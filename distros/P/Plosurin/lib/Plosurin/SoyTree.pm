#===============================================================================
#
#  DESCRIPTION: util for tree
#
#       AUTHOR:  Aliaksandr P. Zahatski, <zahatski@gmail.com>
#===============================================================================

=head1 NAME

Plosurin::SoyTree - syntax tree

=head1 SYNOPSIS

    my $plo = new Plosurin::SoyTree( src => $self->body );

=head1 DESCRIPTION

Plosurin::SoyTree - syntax tree

=cut

package Soy::Actions;
use strict;
use warnings;
use v5.10;
use Data::Dumper;

sub new {
    my $class = shift;
    bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
}

1;

package Soy::base;
use Data::Dumper;

sub new {
    my $class = shift;
    bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
}

# return undef if ok
# else string with [error] Bad value
# or [warn] not inited variable

sub check {
    my $self = shift;
    return undef;    #ok
}

sub attrs {
    my $self = shift;
    my $attr = $self->{attribute} || [];
    my %attr = ();
    foreach my $rec (@$attr) {
        $attr{ $rec->{name} } = $rec->{value};
    }
    return \%attr;
}

sub childs {
    my $self = shift;
    if (@_) {
        $self->{content} = shift;
    }
    return [] unless exists $self->{content};
    [ @{ $self->{content} } ];
}

sub dump {
    my $self   = shift;
    my $childs = $self->childs;
    my $res    = {};
    if ( scalar(@$childs) ) {
        $res->{childs} = [
            map {
                { ref( $_->{obj} ) => $_->{obj}->dump }
              } @$childs
        ];
    }
    if ( scalar( keys %{ $self->attrs } ) ) {
        $res->{attrs} = $self->attrs;
    }

    $res;

}
1;

package Soy::command_print;
use base 'Soy::base';
1;

package Soy::expression;
use base 'Soy::base';
1;

package Soy::raw_text;
use base 'Soy::base';

1;

package Soy::command_elseif;
use base 'Soy::base';
use Data::Dumper;
use strict;
use warnings;

sub dump {
    my $self = shift;
    return { %{ $self->SUPER::dump() },
        expression => $self->{expression}->dump };
}
1;

package Soy::command_call_self;
use base 'Soy::base';
use strict;
use warnings;
use Data::Dumper;

sub dump {
    my $self = shift;
    my $res  = $self->SUPER::dump;
    $res->{template} = $self->{tmpl_name};
    $res;
}
1;

package Soy::command_call;
use Plosurin::SoyTree;
use base 'Soy::command_call_self';
use strict;
use warnings;

package Soy::command_else;
use base 'Soy::base';
use strict;
use warnings;
1;

package Soy::command_if;
use base 'Soy::base';
use strict;
use warnings;
use v5.10;
use Data::Dumper;

sub dump {
    my $self = shift;
    my %ifs  = ();
    $ifs{'if'} =
      { %{ $self->SUPER::dump }, expression => $self->{expression}->dump, };
    if ( exists $self->{commands_elseif} ) {
        my $elseifs = $self->{commands_elseif};
        $ifs{elseif} = [
            map {
                { ref($_) => $_->dump }
              } @$elseifs
        ];

    }
    if ( my $elseif = $self->{command_else} ) {

        $ifs{else} = { ref($elseif) => $elseif->dump() };
    }

    \%ifs;
}
1;

package Soy::command_param;
use base 'Soy::base';
use warnings;
use strict;
use Data::Dumper;

sub as_perl5 {
    my $self = shift;

    #    my $ctx = shift;
    #die Dumper($self);
    #die $self->childs
    my $str = join ' . ', map { $_->as_perl5(@_) } @{ $self->childs };
    return qq!'$self->{name}' => $str!;
}

sub dump {
    my $self = shift;
    my %res = ( %{ $self->SUPER::dump() }, name => $self->{name}, );
    $res{value} = $self->{value} if exists $self->{value};
    \%res;
}

package Soy::command_param_self;
use base 'Soy::command_param';

package Soy::Node;
use base 'Soy::base';

sub childs {
    [ $_[0]->{obj} ];
}

sub as_perl5 {
    my $self = shift;
    return $self->{obj}->as_perl5(@_);
}

package Soy::command_import;
use strict;
use warnings;
use base 'Soy::base';
1;

# $VAR1 = bless( {
#                  'matchline' => 1,
#                  '' => '{foreach $i in [1..10]}ok{ifempty} oo{/foreach}',
#                  'command_foreach_ifempty' => bless( {
#                                                        'matchline' => 1,
#                                                        '' => '{ifempty} oo',
#                                                        'content' => [
#                                                                       bless( {
#                                                                                'matchline' => 1,
#                                                                                'obj' => bless( {
#                                                                                                  '' => ' oo'
#                                                                                                }, 'Soy::raw_text' ),
#                                                                                '' => ' oo',
#                                                                                'matchpos' => 34
#                                                                              }, 'Soy::Node' )
#                                                                     ],
#                                                        'matchpos' => 25
#                                                      }, 'Soy::command_foreach_ifempty' ),
#                  'expression' => bless( {
#                                           '' => '[1..10]'
#                                         }, 'Soy::expression' ),
#                  'content' => [
#                                 bless( {
#                                          'matchline' => 1,
#                                          'obj' => bless( {
#                                                            '' => 'ok'
#                                                          }, 'Soy::raw_text' ),
#                                          '' => 'ok',
#                                          'matchpos' => 23
#                                        }, 'Soy::Node' )
#                               ],
#                  'local_var' => bless( {
#                                          '' => '$i'
#                                        }, 'Soy::expression' ),
#                  'srcfile' => 'test'
#                }, 'Soy::command_foreach' );

package Soy::command_foreach;
use strict;
use warnings;
use base 'Soy::base';

sub get_var_name {
    my $self = shift;
    my $name = $self->{local_var}->{''};
    $name =~ /\$(\w+)/ ? $1 : undef;
}

sub get_ifempty {
    my $self = shift;
    $self->{command_foreach_ifempty};
}

sub dump {
    my $self = shift;
    my %res  = (
        %{ $self->SUPER::dump() },

        #    expression => $self->{expression}
    );
    if ( exists $self->{command_foreach_ifempty} ) {
        my $ife = $self->{command_foreach_ifempty};
        $res{ifempty} = $ife->dump;

    }
    \%res;
}

package Soy::command_foreach_ifempty;
use strict;
use warnings;
use base 'Soy::base';

package Soy::Expression;
use strict;
use warnings;
use Regexp::Grammars;
use Plosurin::Grammar;
use base 'Soy::expression';

sub new {
    my $class = shift;
    bless( ( $#_ == 0 ) ? { '' => shift } : {@_}, ref($class) || $class );
}

1;

package Soy::expression;
use strict;
use warnings;
use Regexp::Grammars;
use Plosurin::Grammar;
use Plosurin::Utl::ExpMapVariables;

use Data::Dumper;
use base 'Soy::base';

=head2 parse {map_of_variables}

    my $e = new Soy::Expresion('1+2');
    $e->parse({w=>"local_variable"});


=cut

sub parse {
    my $self            = shift;
    my $var_map         = shift;
    my $template_params = shift;
    my $txt             = $self->{''};
    my $q               = qr{
     <extends: Plosurin::Exp::Grammar>
    <nocontext:>
    <expr>
    }xms;
    if ( $txt =~ $q ) {
        my $tree = $/{expr};
        my $p    = new Plosurin::Utl::ExpMapVariables(
            vars   => $var_map,
            params => $template_params
        );
        $p->visit($tree);
        return $tree;
    }
    else { return "BAD" }
}

package Exp::base;
use Data::Dumper;
use base 'Soy::base';

sub new {
    my $class = shift;
    bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
}

sub childs {
    my $self = shift;
    return [];
}

sub as_perl5 {
    my $self = shift;
    die "Method as_perl5 not implemented for " . ref($self);
}

package Exp::Var;
use strict;
use warnings;
use Data::Dumper;
use base 'Exp::base';

sub as_perl5 {
    my $self = shift;
    return "\$$self->{Ident}";
}

package Exp::Digit;
use strict;
use warnings;
use Data::Dumper;
use base 'Exp::base';

sub as_perl5 {
    my $self = shift;
    return $self->{''};
}

package Exp::add;
use strict;
use warnings;
use Data::Dumper;
use base 'Exp::base';

sub as_perl5 {
    my $self = shift;
    return $self->{a}->as_perl5() . $self->{op} . $self->{b}->as_perl5();
}

sub childs {
    my $self = shift;
    return [ $self->{a}, $self->{b} ];
}

package Exp::mult;
use strict;
use warnings;
use Data::Dumper;
use base 'Exp::add';
1;

package Exp::String;
use strict;
use warnings;
use Data::Dumper;
use base 'Exp::base';

sub as_perl5 {
    my $self = shift;
    return "'$self->{value}'";
}

package Exp::list;
use strict;
use warnings;
use Data::Dumper;
use base 'Exp::base';

sub childs {
    my $self = shift;
    if (@_) {
        $self->{expr} = \@_;
    }
    return $self->{expr};
}

sub as_perl5 {
    my $self = shift;
    return '[' . join( ",", map { $_->as_perl5() } @{ $self->childs } ) . "]";
}

package Plosurin::SoyTree;
use strict;
use warnings;
use v5.10;
use Data::Dumper;
use Plosurin::Grammar;
use Regexp::Grammars;

=head2 new

    my $st = new Plosurin::SoyTree( 
            src => "txt",
            srcfile=>"filesrc",
            offset=>0
            );

=cut

sub new {
    my $class = shift;
    my $self = bless( ( $#_ == 0 ) ? shift : {@_}, ref($class) || $class );
    $self->{srcfile} //= "UNKNOWN";
    $self->{offset}  //= 0;
    if ( my $src = $self->{src} ) {
        unless ( $self->{_tree} = $self->parse($src) ) { return $self->{_tree} }
    }
    $self;
}

=head2  parse

return [node1, node2]

=cut

sub parse {
    my $self = shift;
    my $str  = shift || return [];
    my $q    = shift || qr{
     <extends: Plosurin::Grammar>
#    <debug:step>
    \A  <[content]>* \Z
    }xms;
    if ( $str =~ $q->with_actions( new Soy::Actions:: ) ) {
        my $raw_tree = {%/};

        #setup filename and offsets
        use Plosurin::Utl::SetLinePos;
        my $line_num_visiter = new Plosurin::Utl::SetLinePos::
          srcfile => $self->{srcfile},
          offset  => $self->{offset};
        $line_num_visiter->visit( $raw_tree->{content} );

        #check errors
        return $raw_tree;
    }
    else {
        "bad template";
    }
}

=head2 raw 

return syntax tree

=cut

sub raw_tree {
    $_[0]->{_tree} || {};
}

=head2 reduce_tree

Union raw_text nodes

=cut

sub reduced_tree {
    my $self = shift;
    my $tree = shift || $self->raw_tree->{content} || return [];
    my @res  = ();
    my @tmp = @$tree;    #copy for protect from modify orig tree
    while ( my $node = shift @tmp ) {

        #skip first node
        #skip all non text nodes
        if ( ref( $node->{obj} ) ne 'Soy::raw_text' || scalar(@res) == 0 ) {
##            if ( my $sub_tree = $node->{obj}->childs ) {
##                $node->{obj}->childs( $self->reduced_tree($sub_tree) );
######                 $self->reduced_tree($sub_tree);
            #           }
            push @res, $node;
            next;
        }
        my $prev = pop @res;
        unless ( ref( $prev->{obj} ) eq 'Soy::raw_text' ) {
            push @res, $prev;
        }
        else {

            #now union !
            $node->{obj} = Soy::raw_text->new(
                { '' => $prev->{obj}->{''} . $node->{obj}->{''} } );
            $node->{matchline} = $prev->{matchline};
            $node->{matchpos}  = $node->{matchpos};
        }
        push @res, $node;
    }
    \@res;
}

=head2 dump_tree($obj1 [, $objn])

Minimalistic tree
return [ "clasname", {key1=>key2} ] 

=cut

sub dump_tree {
    my $self = shift;
    my @res  = ();
    foreach my $rec ( @{ shift || [] } ) {
        my $obj = $rec->{obj};
        push @res, { ref($obj) => $obj->dump() };
    }
    \@res;
}
1;
__END__

=head1 SEE ALSO

Closure Templates Documentation L<http://code.google.com/closure/templates/docs/overview.html>

Perl 6 implementation L<https://github.com/zag/plosurin>


=head1 AUTHOR

Zahatski Aliaksandr, <zag@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

