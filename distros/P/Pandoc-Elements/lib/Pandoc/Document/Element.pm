package Pandoc::Document::Element;
use strict;
use warnings;
our $VERSION = $Pandoc::Document::VERSION;
use JSON ();
use Scalar::Util qw(reftype blessed);
use Pandoc::Walker ();
use subs qw(walk query transform);    # Silence syntax warnings

sub to_json {
    JSON->new->utf8->canonical->convert_blessed->encode( $_[0] );
}

sub TO_JSON {

    # Run everything thru this method so arrays/hashes are cloned
    # and objects without TO_JSON methods are stringified.
    # Required to ensure correct scalar types for Pandoc.

# There is no easy way in Perl to tell if a scalar value is already a string or number,
# so we stringify all scalar values and numify/boolify as needed afterwards.

    my ( $ast, $maybe_blessed ) = @_;
    if ( $maybe_blessed && blessed $ast ) {
        return $ast if $ast->can('TO_JSON');    # JSON.pm will convert
             # may have overloaded stringification! Should we check?
             # require overload;
          # return "$ast" if overload::Method($ast, q/""/) or overload::Method($ast, q/0+/);
          # carp "Non-stringifiable object $ast";
        return "$ast";
    }
    elsif ( 'ARRAY' eq reftype $ast ) {
        return [ map { ref($_) ? TO_JSON( $_, 1 ) : "$_"; } @$ast ];
    }
    elsif ( 'HASH' eq reftype $ast ) {
        my %ret = %$ast;
        while ( my ( $k, $v ) = each %ret ) {
            $ret{$k} = ref($v) ? TO_JSON( $v, 1 ) : "$v";
        }
        return \%ret;
    }
    else { return "$ast" }
}

sub name        { $_[0]->{t} }
sub content     {
   my $e = shift;
   $e->set_content(@_) if @_;
   $e->{c}
}
sub set_content { # TODO: document this
   my $e = shift;
   $e->{c} = @_ == 1 ? $_[0] : [@_]
}
sub is_document { 0 }
sub is_block    { 0 }
sub is_inline   { 0 }
sub is_meta     { 0 }
*walk      = *Pandoc::Walker::walk;
*query     = *Pandoc::Walker::query;
*transform = *Pandoc::Walker::transform;

sub string {

    # TODO: fix issue #4 to avoid this duplication
    if ( $_[0]->name =~ /^(Str|Code|CodeBlock|Math|MetaString)$/ ) {
        return $_[0]->content;
    }
    elsif ( $_[0]->name =~ /^(LineBreak|SoftBreak|Space)$/ ) {
        return ' ';
    }
    join '', @{
        $_[0]->query(
            {
                'Str|Code|CodeBlock|Math|MetaString'  => sub { $_->content },
                'LineBreak|Space|SoftBreak' => sub { ' ' },
            }
        );
    };
}

# TODO: replace by new class Pandoc::Selector with compiled code
sub match {
    my $self = shift;
    foreach my $selector ( split /\|/, shift ) {
        return 1 if $self->match_simple($selector);
    }
    return 0;
}

sub match_simple {
    my ( $self, $selector ) = @_;
    $selector =~ s/^\s+|\s+$//g;

    # name
    return 0
      if $selector =~ s/^([a-z]+)\s*//i and lc($1) ne lc( $self->name );
    return 1 if $selector eq '';

    # type
    if ( $selector =~ s/^:(document|block|inline|meta)\s*// ) {
        my $method = "is_$1";
        return 0 unless $self->$method;
        return 1 if $selector eq '';
    }

    # id and/or classes
    return 0 unless $self->can('match_attributes');
    return $self->match_attributes($selector);
}

