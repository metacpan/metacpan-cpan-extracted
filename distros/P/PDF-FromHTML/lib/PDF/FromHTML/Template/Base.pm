package PDF::FromHTML::Template::Base;

use strict;

BEGIN {
}

use PDF::FromHTML::Template::Constants qw(
    %Verify
);

use PDF::FromHTML::Template::Factory;

sub new
{
    my $class = shift;

    push @_, %{shift @_} while UNIVERSAL::isa($_[0], 'HASH');
    (@_ % 2) && die "$class->new() called with odd number of option parameters", $/;

    my %x = @_;

    # Do not use a hashref-slice here because of the uppercase'ing
    my $self = {};
    $self->{uc $_} = $x{$_} for keys %x;

    $self->{__THIS_HAS_RENDERED__} = 0;

    bless $self, $class;
}

sub isa { PDF::FromHTML::Template::Factory::isa(@_) }

# These functions are used in the P::T::Container & P::T::Element hierarchies

sub _validate_option
{
    my $self = shift;
    my ($option, $val_ref) = @_;

    $option = uc $option;
    return 1 unless exists $Verify{$option} && UNIVERSAL::isa($Verify{$option}, 'HASH');

    if (defined $val_ref)
    {
        if (!defined $$val_ref)
        {
            $$val_ref = $Verify{$option}{'__DEFAULT__'};
        }
        elsif (!exists $Verify{$option}{$$val_ref})
        {
            my $name = ucfirst lc $option;
            warn "$name '$$val_ref' unsupported. Defaulting to '$Verify{$option}{'__DEFAULT__'}'", $/;
            $$val_ref = $Verify{$option}{'__DEFAULT__'};
        }
    }
    elsif (!defined $self->{$option})
    {
        $self->{$option} = $Verify{$option}{'__DEFAULT__'};
    }
    elsif (!exists $Verify{$option}{$self->{$option}})
    {
        my $name = ucfirst lc $option;
        warn "$name '$self->{$option}' unsupported. Defaulting to '$Verify{$option}{'__DEFAULT__'}'", $/;
        $self->{$option} = $Verify{$option}{'__DEFAULT__'};
    }

    return 1;
}

sub calculate { ($_[1])->get(@_[0,2]) }
#{
#    my $self = shift;
#    my ($context, $attr) = @_;
#
#    return $context->get($self, $attr);
#}

sub enter_scope { ($_[1])->enter_scope($_[0]) }
#{
#    my $self = shift;
#    my ($context) = @_;
#
#    return $context->enter_scope($self);
#}

sub exit_scope { ($_[1])->exit_scope(@_[0, 2]) }
#{
#    my $self = shift;
#    my ($context, $no_delta) = @_;
#
#    return $context->exit_scope($self, $no_delta);
#}

sub deltas
{
#    my $self = shift;
#    my ($context) = @_;

    return {};
}

sub reset            { $_[0]{__THIS_HAS_RENDERED__} = 0 }
sub mark_as_rendered { $_[0]{__THIS_HAS_RENDERED__} = 1 }
sub has_rendered     { $_[0]{__THIS_HAS_RENDERED__} }
sub should_render    { ($_[0]{__THIS_HAS_RENDERED__}) || (($_[1])->should_render($_[0])) }

sub resolve
{
#    my $self = shift;
#    my ($context) = @_;

    '';
}

sub render
{
#    my $self = shift;
#    my ($context) = @_;

    return 1;
}

sub begin_page
{
#    my $self = shift;
#    my ($context) = @_;

    return 1;
}

sub end_page
{
#    my $self = shift;
#    my ($context) = @_;

    return 1;
}

1;
__END__
