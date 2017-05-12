package Module::Overview;

=head1 NAME

Module::Overview - print/graph module(s) information

=head1 SYNOPSIS

    use Module::Overview;
    
	my $mo = Module::Overview->new({
		'module_name' => 'Module::Overview',
	});
    
    print $mo->text_simpletable;
    
    my $graph = $mo->graph;    # Graph::Easy
    open my $DOT, '|dot -Tpng -o graph.png' or die ("Cannot open pipe to dot: $!");
    print $DOT $graph->as_graphviz;
    close $DOT;

=cut

use warnings;
use strict;

our $VERSION = '0.01';

use 5.010;

use Class::Sniff;
use Text::SimpleTable;
use Module::ExtractUse;
use Graph::Easy;
use Carp 'confess';

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw{
    module_name
    recursive
    recursion_filter
    hide_methods
});

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    
    confess('module_name is mandatory property')
        if not $self->module_name;
    
    return $self;
}

sub get {
    my $self        = shift;
    my $module_name = shift || $self->{'module_name'};
    
    my $recursion_filter = $self->{'recursion_filter'};

    my %overview;
    
    eval qq{ use $module_name };
    warn 'error loading "'.$module_name.'" - '.$@ if $@;

    my $sniff = Class::Sniff->new({class => $module_name});
    my $euse  = Module::ExtractUse->new;

    #my $graph    = $sniff->graph;   # Graph::Easy
    #print $sniff->report;
    #print join("\n", $sniff->methods), "\n";
    $overview{'class'} = $module_name;
    $overview{'parents'} = [
        grep { not ($_ ~~ [qw(Exporter)]) }     # skip uninteresting
        grep { $_ !~ m{^[0-9._]+$} }            # skip perl versions
        $sniff->parents
    ];
    delete $overview{'parents'}
        if not @{$overview{'parents'}};
    $overview{'classes'} = [
        grep { not ($_ ~~ $overview{'parents'}) }  # skip parents
        grep { not ($_ ~~ [qw(Exporter)]) }        # skip uninteresting
        grep { $_ !~ m{^[0-9._]+$} }               # skip perl versions
        grep { $_ ne $module_name }                # skip self
        $sniff->classes
    ];
    delete $overview{'classes'}
        if not @{$overview{'classes'}};
    
    my $module_name_path = $module_name.'.pm';
    $module_name_path =~ s{::}{/}g;
    if (exists $INC{$module_name_path} and (-r $INC{$module_name_path})) {
        $euse->extract_use($INC{$module_name_path});
        $DB::single=1;
        $overview{'uses'} = [
            grep { (not $recursion_filter) or ($_ =~ m/$recursion_filter/) }   # filter modules
            grep { not ($_ ~~ $overview{'parents'}) }                          # skip parents
            grep { not ($_ ~~ [qw(strict warnings constant vars Exporter)]) }  # skip uninteresting
            grep { $_ !~ m{^[0-9._]+$} }                                       # skip perl versions
            sort
            $euse->array
        ];
        delete $overview{'uses'}
            if not @{$overview{'uses'}};
    }

    my (@methods, @methods_imported);
    while (my ($method, $classes) = each %{$sniff->{methods}}) {
        my $class = ${$classes}[0];
        my $method_desc = $method.'()'.($class ne $module_name ? ' ['.$class.']' : '');

        # source - Pod::Coverage _get_syms()
        # see if said method wasn't just imported from elsewhere
        my $glob = do { no strict 'refs'; \*{$class.'::'.$method} };
        my $o = B::svref_2object($glob);
        # in 5.005 this flag is not exposed via B, though it exists
        my $imported_cv = eval { B::GVf_IMPORTED_CV() } || 0x80;
        my $imported = $o->GvFLAGS & $imported_cv;

        if ($imported) {
            push @methods_imported, $method_desc;
            next;
        }
        
        push @methods, $method_desc;
    }
    $overview{'methods'}          = [ sort @methods ]
        if @methods and (not $self->{'hide_methods'});
    $overview{'methods_imported'} = [ sort @methods_imported ]
        if @methods_imported and (not $self->{'hide_methods'});
    
    return \%overview;
}

sub text_simpletable {
    my $self = shift;
    my $module_name = shift || $self->{'module_name'};
    
    my $module_overview = $self->get($module_name);    
    my $table = Text::SimpleTable->new(16, 60);

    $table->row('class', $module_overview->{'class'});
    if ($module_overview->{'parents'} || $module_overview->{'classes'}) {
        $table->hr;
    }
    if ($module_overview->{'parents'}) {
        $table->row('parents', join("\n", @{$module_overview->{'parents'}}));
    }
    if ($module_overview->{'classes'}) {
        $table->row('classes', join("\n", @{$module_overview->{'classes'}}));
    }
    if ($module_overview->{'uses'}) {
        $table->hr;
        $table->row('uses', join("\n", @{$module_overview->{'uses'}}));
    }
    if ($module_overview->{'methods'}) {
        $table->hr;
        $table->row('methods', join("\n", @{$module_overview->{'methods'}}));
    }
    if ($module_overview->{'methods_imported'}) {
        $table->hr;
        $table->row('methods_imported', join("\n", @{$module_overview->{'methods_imported'}}));
    }
    return $table->draw;
}

sub graph {
    my $self = shift;
    my $module_name = shift || $self->{'module_name'};
    my $graph = shift || Graph::Easy->new();
    
    my $recursion_filter = $self->{'recursion_filter'};
    return $graph
        if ($recursion_filter and ($module_name !~ m/$recursion_filter/));
    
    my $module_overview = $self->get($module_name);
    
    $graph->add_node($module_name)->set_attributes({'font-size' => '150%', 'textstyle' => 'bold', 'fill' => 'lightgrey'});
    if ($module_overview->{'parents'}) {
        my $module_name_parent = $module_name.' parent';
        $graph->add_node($module_name_parent)->set_attributes({
            'label'     => 'parent',
            'shape'     => 'ellipse',
            'font-size' => '75%',
        });
        $graph->add_edge_once($module_name => $module_name_parent);

        foreach my $parent (@{$module_overview->{'parents'}}) {
            $graph->add_node($parent);
            
            my $e = $graph->add_edge_once($module_name_parent, $parent);
            
            #my $e = $graph->add_edge_once($module_name, $parent, 'parent');
            
            $self->graph($parent, $graph)
                if ($e and $self->{'recursive'});
        }
    }
    if ($module_overview->{'uses'}) {
        my $module_name_use = $module_name.' use';
        $graph->add_node($module_name_use)->set_attributes({
            'label'     => 'use',
            'shape'     => 'ellipse',
            'font-size' => '75%',
        });
        $graph->add_edge_once($module_name => $module_name_use);

        foreach my $use (@{$module_overview->{'uses'}}) {
            $graph->add_node($use);
            
            my $e = $graph->add_edge_once($module_name_use, $use);
            
            #my $e = $graph->add_edge_once($module_name, $use, 'use');
            
            $self->graph($use, $graph)
                if ($e and $self->{'recursive'});
        }
    }
    if ($module_overview->{'methods'}) {
        my $module_name_methods = $module_name.' methods';
        $graph->add_node($module_name_methods)->set_attributes({
            'label'       => join('\n', @{$module_overview->{'methods'}}),
            'font-size'   => '75%',
            'align'       => 'left',
            'borderstyle' => 'dashed',
        });
        $graph->add_edge_once($module_name => $module_name_methods, 'methods');
    }
    if ($module_overview->{'methods_imported'}) {
        my $module_name_methods = $module_name.' methods_imported';
        $graph->add_node($module_name_methods)->set_attributes({
            'label'       => join('\n', @{$module_overview->{'methods_imported'}}),
            'font-size'   => '75%',
            'align'       => 'left',
            'borderstyle' => 'dashed',
        });
        $graph->add_edge_once($module_name => $module_name_methods, 'methods imported');
    }

    return $graph;
}

'OV?';

__END__

=head1 DESCRIPTION

    .------------------+--------------------------------------------------------------.
    | class            | Module::Overview                                             |
    +------------------+--------------------------------------------------------------+
    | parents          | Class::Accessor::Fast                                        |
    | classes          | Class::Accessor                                              |
    +------------------+--------------------------------------------------------------+
    | uses             | Carp                                                         |
    |                  | Class::Sniff                                                 |
    |                  | Graph::Easy                                                  |
    |                  | Module::ExtractUse                                           |
    |                  | Text::SimpleTable                                            |
    +------------------+--------------------------------------------------------------+
    | methods          | _carp() [Class::Accessor]                                    |
    |                  | _croak() [Class::Accessor]                                   |
    |                  | _mk_accessors() [Class::Accessor]                            |
    |                  | accessor_name_for() [Class::Accessor]                        |
    |                  | best_practice_accessor_name_for() [Class::Accessor]          |
    |                  | best_practice_mutator_name_for() [Class::Accessor]           |
    |                  | follow_best_practice() [Class::Accessor]                     |
    |                  | get()                                                        |
    |                  | graph()                                                      |
    |                  | import() [Class::Accessor]                                   |
    |                  | make_accessor() [Class::Accessor::Fast]                      |
    |                  | make_ro_accessor() [Class::Accessor::Fast]                   |
    |                  | make_wo_accessor() [Class::Accessor::Fast]                   |
    |                  | mk_accessors() [Class::Accessor]                             |
    |                  | mk_ro_accessors() [Class::Accessor]                          |
    |                  | mk_wo_accessors() [Class::Accessor]                          |
    |                  | mutator_name_for() [Class::Accessor]                         |
    |                  | new()                                                        |
    |                  | set() [Class::Accessor]                                      |
    |                  | text_simpletable()                                           |
    +------------------+--------------------------------------------------------------+
    | methods_imported | _hide_methods_accessor()                                     |
    |                  | _module_name_accessor()                                      |
    |                  | _recursion_filter_accessor()                                 |
    |                  | _recursive_accessor()                                        |
    |                  | confess()                                                    |
    |                  | hide_methods()                                               |
    |                  | module_name()                                                |
    |                  | recursion_filter()                                           |
    |                  | recursive()                                                  |
    |                  | subname() [Class::Accessor]                                  |
    '------------------+--------------------------------------------------------------'

=head1 PROPERTIES

    module_name
    recursive
    recursion_filter
    hide_methods

=head1 METHODS

=head2 new()

Object constructor.

=head2 get

Return hash ref with module overview.

=head2 text_simpletable

Returns string with tabular text representation of L</get>.

=head2 graph

Returns L<Graph::Easy> with representation of L</get>.

=head1 SEE ALSO

L<Class::Sniff>, L<Module::ExtractUse>

=head1 AUTHOR

jozef@kutej.net, C<< <jkutej at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
