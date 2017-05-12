use strict;
use warnings;

package Paludis::ResumeState::Serialization::Grammar;
BEGIN {
  $Paludis::ResumeState::Serialization::Grammar::AUTHORITY = 'cpan:KENTNL';
}
{
  $Paludis::ResumeState::Serialization::Grammar::VERSION = '0.01000410';
}

# ABSTRACT: A Regexp::Grammars grammar for parsing Paludis Resume-states

use Regexp::Grammars;
use Regexp::Grammars::Common::String;


our $CLASS_CALLBACK;
our $LIST_CALLBACK;

{
  ## no critic ( ProhibitMultiplePackages )
  package    # Hide
    Paludis::ResumeState::Serialization::Grammar::FakeClass;

  package    # Hide
    Paludis::ResumeState::Serialization::Grammar::FakeList;
}

sub _classize {
  my ( $name, $parameters, $parameters_list, $extra ) = @_;
  if ( defined $CLASS_CALLBACK ) {
    return $CLASS_CALLBACK->( $name, $parameters, $parameters_list, $extra );
  }
  bless $parameters, __PACKAGE__ . '::FakeClass';
  $parameters->{_classname} = $name;
  return $parameters;
}

sub _listize {
  my ($parameters) = @_;
  if ( defined $LIST_CALLBACK ) {
    return $LIST_CALLBACK->($parameters);
  }
  bless $parameters, __PACKAGE__ . '::FakeArray';
  return $parameters;
}

my $t;


sub grammar {
  _build_grammar() unless defined $t;
  return $t;
}

sub _build_grammar {
  ## no critic ( RegularExpressions )
  $t = qr{

    <extends: Regexp::Grammars::Common::String>
    <nocontext: >

    <ResumeSpec>

    <token: ResumeSpec>
        <classname=([A-Z][A-Za-z0-9]+)>
        @
        <pid=(\d+)>
        \(<parameters=paramlist>\)

    (?{
        if( ref $MATCH{parameters} ){
            my @parameters = @{$MATCH{parameters}};
            my %hash;
            my @list;
            my %extra = ();
            my $i;
            for( @parameters ){
                $hash{$_->{label}} = $_->{value};
                push @list, [ $_->{label} , $_->{value} ];
                $i++;
            }
            if( scalar keys %hash  == $i ){
                $extra{pid} = $MATCH{pid};
                $MATCH = Paludis::ResumeState::Serialization::Grammar::_classize( $MATCH{classname}, \%hash, \@list, \%extra );
            }


        }
    })

    <token: classname>  [A-Z][A-Za-z0-9]*

    <token: classvalue> <classname>\(<parameters=paramlist>\)

    (?{
        if( not $MATCH{parameters} ) {
            $MATCH = Paludis::ResumeState::Serialization::Grammar::_classize( $MATCH{classname}, {}, [], {} );
        } elsif( ref $MATCH{parameters} ){
            my @parameters = @{$MATCH{parameters} || []};
            my %hash;
            my @list;
            my $i;
            for( @parameters ){
                $hash{$_->{label}} = $_->{value};
                push @list, [ $_->{label} , $_->{value} ];
                $i++;
            }
            if( scalar keys %hash  == $i ){
                $MATCH = Paludis::ResumeState::Serialization::Grammar::_classize( $MATCH{classname}, \%hash, \@list, {}  );
            }


        }
    })

    <token: cvalue>     <classname=(c)>\(<parameters=paramlist>\)
    (?{
        if( not $MATCH{parameters} ){
            $MATCH = Paludis::ResumeState::Serialization::Grammar::_listize( [] );
        } elsif ( ref $MATCH{parameters} and $MATCH{parameters}->[-1]->{label} eq 'count' ){
            my $count = pop @{ $MATCH{parameters} };
            $MATCH{count} = int($count->{value});
            my @items = map { $_->{value} } @{ $MATCH{parameters} };
            $MATCH = Paludis::ResumeState::Serialization::Grammar::_listize( \@items );
        }
    })

    <token: value>      <MATCH=classvalue>|<MATCH=cvalue>|<MATCH=String>
    <token: label>      [a-z0-9_]+

    <token: paramlist>  (|(<[MATCH=parameter]> ** (;))(;)?)

    <token: parameter>  <label>=<value>

    }x;

  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Paludis::ResumeState::Serialization::Grammar - A Regexp::Grammars grammar for parsing Paludis Resume-states

=head1 VERSION

version 0.01000410

=head1 METHODS

=head2 grammar

    my $grammar = Paludis::ResumeState::Serialization::Grammar::grammar();
    if( $data =~ $grammar ){
        do_stuff_with(\%/);
    }

Returns a grammar regular expression object formed with L<< C<Regexp::Grammars>|Regexp::Grammars >>.

To tune the data it provides, localise L</$CLASS_CALLBACK> and L</$LIST_CALLBACK>.

=head1 CLASS VARIABLES

The following variables may be localised and assigned to
subs as callbacks to tune how the regular expressions grammar works.

=head2 $CLASS_CALLBACK

    local $Paludis::ResumeState::Serialization::Grammar::CLASS_CALLBACK = sub {
        my ( $name, $parameters, $parameters_list, $extra ) = @_;
        return { whatever }
    };

This callback is called every time a parse completes a 'class' entry, allowing
you to filter it however you want.

B<WARNING> L<< C<Regexp::Grammars>|Regexp::Grammars >> states that during the traversal of a grammar, you really should avoid calling anything that itself uses regular expressions, as it could be broken, or interfere with the grammars parsing.

This includes L<< C<Moose>|Moose >> due to it using Regular Expressions for type-constraints.

If you need an advanced processing, its recommended to do just enough to identify the instance later, and then pass over the data and do the powerful magic after the grammar has run its course.

=head3 $name

Is the name of the class we most recently discovered.

=head3 $parameters

Is a hash-ref of all the classes parameters, treated as a key-value set.

    Foo(key=value;bar=baz;quux=doo;);

Thus produces

    { bar => 'baz', key => 'value', quux => 'doo' }

=head3 $parameters_list

Similar to $parameters, but optimised to preserve ordering and preserve format.

    [ ['key', 'value' ], [ 'bar' , 'baz' ], ['quux', 'doo' ] ]

=head3 $extras

Periodically, the parser may return a few extra bits of data that don't fall under the usual classifications. At present, its only the C<pid> property of the C<ResumeData> object, i.e.:

    ResumeData@1234(foo=bar;);

Will arrive as

    $code->('ResumeData', { foo  => 'bar' }, [['foo','bar']], { pid => '1234' });

=head2 $LIST_CALLBACK

    local $Paludis::ResumeState::Serialization::Grammar::LIST_CALLBACK = sub {
        my ( $parameters ) = @_;
        return { whatever }
    };

Paludis resume files have a special case class which behaves like a list:

    Foo(bar=c(1=baz;2=quux;3=doo;count=3;););

We detect this intent and pass it to $LIST_CALLBACK as an array.

    $code->(['baz','quux','doo' ]);

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
