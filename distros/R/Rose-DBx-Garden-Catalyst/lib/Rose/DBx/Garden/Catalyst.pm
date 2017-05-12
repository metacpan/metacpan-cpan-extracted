package Rose::DBx::Garden::Catalyst;

use warnings;
use strict;
use base qw( Rose::DBx::Garden );
use Carp;
use Path::Class;
use Data::Dump qw( dump );
use Tree::Simple;
use Tree::Simple::Visitor::ToNestedHash;
use Class::Inspector;
use File::Copy;
use CatalystX::CRUD::YUI::TT;
use File::Slurp::Tiny;

use Rose::Object::MakeMethods::Generic (
    'scalar --get_set_init' => [qw( catalyst_prefix controller_prefix )],
    boolean                 => [ 'tt' => { default => 1 }, ]
);

our $VERSION = '0.180';

=head1 NAME

Rose::DBx::Garden::Catalyst - plant Roses in your Catalyst garden

=head1 SYNOPSIS

    # create a Catalyst app
    > catalyst.pl MyApp
        
    # create a Rose::DBx::Garden::Catalyst script
    > cat mk_cat_garden.pl
    use Rose::DBx::Garden::Catalyst;
    use MyDB;  # isa Rose::DB
    
    my $garden = Rose::DBx::Garden::Catalyst->new(
        catalyst_prefix   => 'MyApp',
        controller_prefix => 'RDGC',
        garden_prefix     => 'MyRDBO',
        db                => MyDB->new,
        tt                => 1,  # make Template Toolkit files
    );
                    
    $garden->plant('MyApp/lib');
    
    # run your script
    > perl mk_cat_garden.pl
    
    # edit your MyApp.pm file:
    > vi MyApp/lib/MyApp.pm
     
     # serve static assets
     use Catalyst qw/
         Static::Simple::ByClass
     /;
     
     __PACKAGE__->config(
        'Plugin::Static::Simple::ByClass' => {
            classes => [qw( CatalystX::CRUD::YUI::TT )],
        }
        'default_view' => 'RDGC',
     );
    
     # after __PACKAGE__->setup();
     # add these lines:
     
     use MRO::Compat;
     use mro 'c3';
     Class::C3::initialize();
        
    # start your Catalyst dev server
    > cd MyApp
    > perl script/myapp_server.pl
    
    # enjoy the fruits at http://localhost:3000/rdgc

=head1 DESCRIPTION

Rose::DBx::Garden::Catalyst extends Rose::DBx::Garden to create
Catalyst component scaffolding.  These created components use the RDBO
and RHTMLO classes that the Garden class produces.  The base
Controller, Model and View classes are simple subclasses of
CatalystX::CRUD::YUI.

This module works on the assumption that 1 table == 1 form == 1 controller class == 1 model class.

By default this class creates stub Template Toolkit files for use
with the RDBO and RHTMLO CRUD components. If you use a different templating
system, just set the C<tt> option to 0.

=head1 METHODS

Only new or overridden methods are documented here.

=cut

=head2 init_controller_prefix

The namespace where Catalyst Controllers are created. Will also be lowercased
and serve as the URI path namespace for all RDGC actions.

Default: RDGC

=cut

sub init_controller_prefix {'RDGC'}

=head2 init_base_code

Override the base method to create methods useful to RDBO classes
used in Catalyst.

=cut

sub init_base_code {
    return <<EOF;

use base qw( Rose::DBx::Garden::Catalyst::Object );

EOF
}

=head2 init_base_form_class_code

Custom base Form code to implement features that template will require.

=cut

sub init_base_form_class_code {
    my $self              = shift;
    my $controller_prefix = $self->controller_prefix;
    return <<EOF;
use Carp;
use base qw( Rose::DBx::Garden::Catalyst::Form );

sub init_metadata {
    my \$self = shift;
    return \$self->metadata_class->new( 
        form                => \$self,
        controller_prefix   => '$controller_prefix',
    );
}

EOF
}

=head2 init_catalyst_prefix

Defaults to 'MyApp'.

=cut

sub init_catalyst_prefix {'MyApp'}

=head2 base_tt_path

Returns controller_prefix() transformed to a file path.

=cut

sub base_tt_path {
    my $self = shift;
    my $cp   = $self->controller_prefix;
    $cp =~ s,::,/,g;
    return lc($cp);
}

=head2 plant( I<path/to/my/catapp> )

Override the base method to create Catalyst-related files in addition
to the basic Garden files.

=cut

sub plant {
    my $self   = shift;
    my $garden = $self->SUPER::plant(@_);
    $self->make_catalyst( $garden, $self->module_dir );
}

=head2 make_catalyst( I<class_names>, I<path> )

Does the actual file creation of Catalyst files. Called by plant().

I<class_names> should be a hash ref of RDBO => RHTMLO class names, as returned
by Rose::DBx::Garden->plant(). If you have existing RDBO and RHTMLO classes
that have namespaces inconsistent with the conventions in Rose::DBx::Garden,
they B<should> still work. Just map the RDBO => RHTMLO classes in your
I<class_names> hash ref.

=cut

sub make_catalyst {
    my $self   = shift;
    my $garden = shift or croak "hash of class names required";
    my $path   = shift or croak "path required";
    unless ( ref($garden) eq 'HASH' ) {
        croak "class_names must be a HASH ref";
    }
    my %rhtmlo2rdbo = reverse %$garden;
    delete $rhtmlo2rdbo{1};
    my @form_classes = keys %rhtmlo2rdbo;

    # make sure this looks like a Catalyst dir.
    # use same criteria as the Catalst
    # path_to() method: Makefile.PL or Build.PL
    my $dir  = dir($path);
    my $root = $dir->parent;
    unless ( -f $root->file('Makefile.PL') or -f $root->file('Build.PL') ) {
        croak "$root does not look like a Catalyst application directory "
            . "(no Makefile.PL or Build.PL file)";
    }

    # make CRUD controllers and models for each Form class.
    # we only care about Form classes because those do not
    # represent map classes, which should be invisible to normal usage.

    my $catprefix         = $self->catalyst_prefix;
    my $gardprefix        = $self->garden_prefix;
    my $controller_prefix = $self->controller_prefix;
    my @controllers;
    my %tree;

    # parent controller
    $self->_make_file(
        join( '::', $catprefix, 'Controller', $controller_prefix ),
        $self->_make_parent_controller );

    # our TT View
    $self->_make_file( join( '::', $catprefix, 'View', 'RDGC' ),
        $self->_make_view );

    # our Excel export View
    $self->_make_file( join( '::', $catprefix, 'View', 'Excel' ),
        $self->_make_excel_view );

    # base Controller and Model classes
    $self->_make_file(
        join( '::', $catprefix, 'Base', 'Controller', 'RHTMLO' ),
        $self->_make_base_rhtmlo_controller );
    $self->_make_file( join( '::', $catprefix, 'Base', 'Model', 'RDBO' ),
        $self->_make_base_rdbo_model );

    # sort so menu comes out sorted
    for my $rhtmlo ( sort @form_classes ) {
        my $rdbo = $rhtmlo2rdbo{$rhtmlo};
        my $bare = $rdbo;
        $bare =~ s/^${gardprefix}:://;
        my $controller_class
            = join( '::', $catprefix, 'Controller', $controller_prefix,
            $bare );
        my $model_class
            = join( '::', $catprefix, 'Model', $controller_prefix, $bare );
        $self->_make_file(
            $controller_class,
            $self->_make_controller(
                $rdbo, $rhtmlo, $controller_class, $model_class
            )
        );
        $self->_make_file( $model_class,
            $self->_make_model( $model_class, $rdbo ) );
        push( @controllers, $controller_class );

        # create menus, split by :: into flyout levels (max 4 deep)
        my (@parts) = split( m/::/, $bare );
        my $top = shift @parts;
        $tree{$top} = Tree::Simple->new( $top, Tree::Simple->ROOT )
            unless exists $tree{$top};
        my $prev = $tree{$top};
        for my $part (@parts) {
            Tree::Simple->new( $part, $prev );
            $prev = $part;
        }
    }

    my $base_url = $self->base_tt_path;

    my @menu_items = ( { href => '/' . $base_url, txt => 'Home' } );
    for my $branch ( sort keys %tree ) {
        my $visitor = Tree::Simple::Visitor::ToNestedHash->new();
        my $subtree = $tree{$branch};
        $subtree->accept($visitor);
        my $m        = $visitor->getResults();
        my $children = $m->[0];
        my %item;
        $item{href} = join( '/', '', $base_url, lc($branch) );
        $item{txt} = $branch;
        my $sub = $self->_make_menu_items( $item{href}, $children );
        $item{items} = $sub if $sub;
        push( @menu_items, \%item );
    }

    # populate templates
    # the idea is to create a 'crud' dir in MyApp/root/
    # with the PROCESS-able .tt files
    # and then add stub .tt files in each _tmpl_path
    # for the CRUD methods

    # convention is template dir called 'root'
    my $tt_dir = dir( $root, 'root' );
    unless ( -d $tt_dir ) {
        croak "$tt_dir does not exist -- cannot create template files";
    }

    # we need 1 dir, possibly 2
    my $rdgc_tt_dir = dir( $tt_dir, 'crud' );      # used to be 'rdgc'
    my $base_tt_dir = dir( $tt_dir, $base_url );
    $rdgc_tt_dir->mkpath(1);
    $base_tt_dir->mkpath(1);

    # write a default welcome page
    $self->_write_tt_file( file( $base_tt_dir, 'default.tt' )->stringify,
        $self->_tt_default_page );

    # write the menu now that we know the dir exists
    $self->_write_tt_file(
        file( $rdgc_tt_dir, 'schema_menu.tt' )->stringify,
        '[% SET menu = '
            . dump( { id => 'schema_menu', items => \@menu_items } ) . '%]'
    );

    # disable stubs for each controller to reduce noise
    # now that CatalystX::CRUD::YUI::View will serve the default .tt
    #
    # stubs for each controller
    #for my $ctrl (@controllers) {
    #        my @tmpl_dir = $self->_tmpl_path_from_controller($ctrl);
    #
    #        for my $stub (qw( search edit view list count )) {
    #            my $method = '_tt_stub_' . $stub;
    #            $self->_write_tt_file(
    #                file( $tt_dir, @tmpl_dir, $stub . '.tt' )->stringify,
    #                $self->$method );
    #        }
    #    }

    # css and js will not work out of the box anymore since
    # they are in the CatalystX::CRUD::YUI package.
    # so find them and copy them locally so that Static::Simple
    # can find them.
    my $cx_crud_yui_tt_path
        = Class::Inspector->loaded_filename('CatalystX::CRUD::YUI::TT');
    $cx_crud_yui_tt_path =~ s/\.pm//;

    my $js_dir = dir( $tt_dir, 'static', 'js' );
    $js_dir->mkpath(1);
    my $css_dir = dir( $tt_dir, 'static', 'css' );
    $css_dir->mkpath(1);
    my $css_crud_dir = dir( $css_dir, 'crud' );
    $css_crud_dir->mkpath(1);

    copy( file( $cx_crud_yui_tt_path, 'static', 'js', 'crud.js' ) . '',
        file( $js_dir, 'crud.js' ) . '' )
        or warn "ERROR: failed to copy crud.js to local static/js\n";
    copy( file( $cx_crud_yui_tt_path, 'static', 'js', 'json.js' ) . '',
        file( $js_dir, 'json.js' ) . '' )
        or warn "ERROR: failed to copy json.js to local static/js\n";
    copy( file( $cx_crud_yui_tt_path, 'static', 'css', 'crud.css' ) . '',
        file( $css_dir, 'crud.css' ) . '' )
        or warn "ERROR: failed to copy crud.css to local static/css\n";

    # all the css files
    my $css_base_dir = dir( $cx_crud_yui_tt_path, 'static', 'css', 'crud' );
    while ( my $css_file = $css_base_dir->next ) {
        next unless -f $css_file;
        copy( $css_file . '',
            file( $css_crud_dir, $css_file->basename ) . '' )
            or warn "ERROR: failed to copy $css_file to $css_crud_dir\n";
    }

    return $garden;
}

sub _make_menu_items {
    my ( $self, $parent, $children ) = @_;
    return unless $children && keys %$children;

    #carp "parent = $parent";
    #carp dump $children;

    my @items;

    for my $child ( sort keys %$children ) {
        my %item;
        $item{href} = join( '/', $parent, lc($child) );
        $item{txt} = $child;
        if ( keys %{ $children->{$child} } ) {
            $item{items}
                = $self->_make_menu_items( $item{href}, $children->{$child} );
        }
        elsif ( $child !~ m/^(Search|Create|List)$/ ) {
            $item{items} = $self->_make_menu_items( $item{href},
                { Search => {}, Create => {}, List => {} } );
        }
        push( @items, \%item );
    }
    return \@items;
}

sub _write_tt_file {
    my ( $self, $tt, $buf, $ext ) = @_;
    my ( $name, $path, $suffix )
        = File::Basename::fileparse( $tt, $ext || qr{\.tt} );

    $path = dir($path);

    unless ( $self->force_install ) {
        return if -s $tt;
    }

    $path->mkpath(1) if $path;

    print "writing $tt\n";
    File::Slurp::Tiny::write_file( $tt, $buf );    # Garden.pm uses File::Slurp::Tiny
}

sub _tt_default_page {
    return <<EOF;
Edit the root/rdgc/default page to change this content.
EOF
}

sub _tt_stub_search {
    return <<EOF;
[% PROCESS rdgc/search.tt %]
EOF
}

sub _tt_stub_list {
    return <<EOF;
[% PROCESS rdgc/list.tt %]
EOF
}

sub _tt_stub_count {
    return <<EOF;
[% PROCESS rdgc/list.tt %]
EOF
}

sub _tt_stub_edit {
    return <<EOF;
[% 
    fields      = {};
    fields.readonly = {'created' = 1, 'modified' = 1}; # common auto-timestamp names
    PROCESS rdgc/edit.tt;
%]
EOF
}

sub _tt_stub_view {
    return <<EOF;
[% 
    fields      = {};
    fields.readonly = {};
    FOREACH f IN form.field_names;
        fields.readonly.\$f = 1;
    END;
    PROCESS rdgc/edit.tt  buttons = 0;
%]
EOF
}

sub _tmpl_path_from_controller {
    my ( $self, $controller ) = @_;
    $controller =~ s/^.*::Controller:://;
    return ( map { lc($_) } split( m/::/, $controller ) );
}

sub _make_parent_controller {
    my $self              = shift;
    my $cat_class         = $self->catalyst_prefix;
    my $controller_prefix = $self->controller_prefix;
    my $base_path         = $self->base_tt_path;

    return <<EOF;
package ${cat_class}::Controller::${controller_prefix};
use strict;
use warnings;
use base qw( Catalyst::Controller );
use MRO::Compat;
use mro 'c3';

sub default : Path {
    my (\$self, \$c) = \@_;
    \$c->stash->{template} = '$base_path/default.tt';
}

1;

EOF
}

sub _make_controller {
    my ( $self, $rdbo_class, $form_class, $contr_class, $model_class ) = @_;
    my $tmpl
        = file( $self->_tmpl_path_from_controller($contr_class), 'edit.tt' );

    my $object_name
        = $self->convention_manager->class_to_table_singular($rdbo_class);

    my $catalyst_prefix = $self->catalyst_prefix;
    my $base_rdbo_class = $self->garden_prefix;

    # just the model short name is wanted.
    # otherwise we get false partial matches.
    $model_class =~ s/^${catalyst_prefix}::Model:://;

    my @pk = $rdbo_class->meta->primary_key_column_names;
    my $pk = join( "', '", @pk );

    return <<EOF;
package $contr_class;
use strict;
use base qw( ${catalyst_prefix}::Base::Controller::RHTMLO );
use MRO::Compat;
use mro 'c3';
use $form_class;

__PACKAGE__->config(
    form_class              => '$form_class',
    init_form               => 'init_with_${object_name}',
    init_object             => '${object_name}_from_form',
    default_template        => '$tmpl',
    model_name              => '$model_class',
    primary_key             => ['$pk'],
    view_on_single_result   => 1,
    page_size               => 50,
);

1;
    
EOF

}

sub _make_base_rhtmlo_controller {
    my $self            = shift;
    my $catalyst_prefix = $self->catalyst_prefix;

    return <<EOF;
package ${catalyst_prefix}::Base::Controller::RHTMLO;
use strict;
use warnings;
use base qw( Rose::DBx::Garden::Catalyst::Controller );
use MRO::Compat;
use mro 'c3';

__PACKAGE__->config(
    default_view    => 'RDGC',
    fmt_to_view_map => {
        html => "RDGC",
        json => "RDGC",
        xls  => "Excel"
    },
);

1;

EOF
}

sub _make_base_rdbo_model {
    my $self      = shift;
    my $catprefix = $self->catalyst_prefix;

    return <<EOF;
package ${catprefix}::Base::Model::RDBO;
use strict;
use warnings;
use base qw( CatalystX::CRUD::Model::RDBO );
use MRO::Compat;
use mro 'c3';

1;

EOF
}

sub _make_model {
    my ( $self, $model_class, $rdbo_class ) = @_;
    my $catprefix = $self->catalyst_prefix;

    return <<EOF;
package $model_class;
use strict;
use base qw( ${catprefix}::Base::Model::RDBO );
use MRO::Compat;
use mro 'c3';

__PACKAGE__->config(
    name                    => '$rdbo_class',
    page_size               => 50,
);

1;

EOF

}

sub _make_view {
    my ($self) = @_;
    my $cat_class = $self->catalyst_prefix;

    return <<EOF;
package ${cat_class}::View::RDGC;
use strict;
use warnings;
use base qw( Rose::DBx::Garden::Catalyst::View );
use MRO::Compat;
use mro 'c3';

1;

EOF
}

sub _make_excel_view {
    my ($self) = @_;
    my $cat_class = $self->catalyst_prefix;

    return <<EOF;
package ${cat_class}::View::Excel;
use strict;
use warnings;
use base qw( CatalystX::CRUD::View::Excel );
use CatalystX::CRUD::YUI;
use MRO::Compat;
use mro 'c3';

sub get_template_params {
    my ( \$self, \$c ) = \@_;
    my \$cvar = \$self->config->{CATALYST_VAR} || 'c';
    return (
        \$cvar => \$c,
        \%{ \$c->stash },
        yui => CatalystX::CRUD::YUI->new,
    );
}

1;

EOF
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 TODO

=over

=item client-side JS validation

Should be straightforward since the Garden nows puts column-type as xhtml class value.

=item RDGC tests

Need a way to reliably test the JS.

=back

=head1 BUGS

Known issues:

=over

=item re-running the script fails to pick up all classes

This is due to issues with @INC and how the RDBO Loader requires classes.
There is no known workaround at the moment.

=item javascript required

The TT templates generated depend heavily on the YUI toolkit 
C<< http://developer.yahoo.com/yui/ >>.
Graceful degredation is not implemented as yet.

=back

Please report any bugs or feature requests to
C<bug-rose-dbx-garden-catalyst at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rose-DBx-Garden-Catalyst>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rose::DBx::Garden::Catalyst

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rose-DBx-Garden-Catalyst>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rose-DBx-Garden-Catalyst>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rose-DBx-Garden-Catalyst>

=item * Search CPAN

L<http://search.cpan.org/dist/Rose-DBx-Garden-Catalyst>

=back

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
