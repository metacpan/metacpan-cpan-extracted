package PDF::FromHTML::Template::Container::Conditional;

#GGG Convert <conditional> to be a special case of <switch>?

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Container);

    use PDF::FromHTML::Template::Container;
}

my %isOp = (
    '='  => '==',
    (map { $_ => $_ } ( '>', '<', '==', '!=', '>=', '<=' )),
    (map { $_ => $_ } ( 'gt', 'lt', 'eq', 'ne', 'ge', 'le' )),
);

# This cannot be within a should_render() function because the conditional needs
# to return true even if the conditional is false. We are indicating that this
# branch has done everything it needs to do, not that this branch is calling for
# a pagebreak.

sub conditional_passes
{
    my $self = shift;
    my ($context) = @_;

    my $name = $context->get($self, 'NAME');
    return 0 unless $name =~ /\S/;

    my $val = $context->param($name);
    $val = @{$val} while UNIVERSAL::isa($val, 'ARRAY');
    $val = ${$val} while UNIVERSAL::isa($val, 'SCALAR');

    my $istrue = (defined $val && $val) ? 1 : 0;
    my $value = $context->get($self, 'VALUE');
    if (defined $value)
    {
        my $op = $context->get($self, 'OP');
        $op = defined $op && exists $isOp{$op}
            ? $isOp{$op}
            : '==';

        my $res;
        for ($op)
        {
            /^>$/  && do { $res = ($val > $value);  last };
            /^<$/  && do { $res = ($val < $value);  last };
            /^==$/ && do { $res = ($val == $value); last };
            /^!=$/ && do { $res = ($val != $value); last };
            /^>=$/ && do { $res = ($val >= $value); last };
            /^<=$/ && do { $res = ($val <= $value); last };
            /^gt$/ && do { $res = ($val gt $value); last };
            /^lt$/ && do { $res = ($val lt $value); last };
            /^eq$/ && do { $res = ($val eq $value); last };
            /^ne$/ && do { $res = ($val ne $value); last };
            /^ge$/ && do { $res = ($val ge $value); last };
            /^le$/ && do { $res = ($val le $value); last };

            die "Unknown operator '$op' in conditional resolve", $/;
        }

        return 1;
    }
    elsif (my $is = uc $context->get($self, 'IS'))
    {
        if ($is eq 'TRUE')
        {
            return $istrue;
        }
        else
        {
            warn "Conditional 'is' value was [$is], defaulting to 'FALSE'" . $/
                if $is ne 'FALSE';

            return !$istrue;
        }
    }

    return $istrue;
}

sub render
{
    my $self = shift;
    my ($context) = @_;

    return 0 unless $self->should_render($context);

    return 1 unless $self->conditional_passes($context);

    return $self->iterate_over_children($context);
}

sub max_of
{
    my $self = shift;
    my ($context, $attr) = @_;

    return 0 unless $self->conditional_passes($context);

    return $self->SUPER::max_of($context, $attr);
}

sub total_of
{
    my $self = shift;
    my ($context, $attr) = @_;

    return 0 unless $self->conditional_passes($context);

    return $self->SUPER::total_of($context, $attr);
}

sub _do_page
{
    my $self = shift;
    return unless $self->conditional_passes(@_);
    return $self->SUPER::_do_page( @_ );
}

sub begin_page
{
    _do_page(@_,'begin_page');
}

sub end_page
{
    _do_page(@_,'end_page');
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::Conditional

=head1 PURPOSE

To conditionally allow children to render

=head1 NODE NAME

CONDITIONAL
IF (an alias for CONDITIONAL)

=head1 INHERITANCE

PDF::FromHTML::Template::Container

=head1 ATTRIBUTES

=over 4

=item * NAME - Required. This is a parameter name, whose value will determine
if the conditional passed or fails. If NAME is not specified, the conditional
will consider to always fail.

=item * OP - defaults to == (numeric equality). If VALUE is specified, this will
be how NAME and VALUE are compared. OP can be any of the 6 numeric comparision
operators or the 6 string comparision operators.

=item * VALUE - if this is specified, OP will be checked. This is a standard
attribute, so if you want a parameter, prepend it with '$'.

=item * IS - If there is no VALUE attribute, this will be checked. IS can be
either 'FALSE' or 'TRUE'. The boolean of NAME will be compared and the
conditional will branch appropriately. If NAME has no value, this will fail.

=item * NONE - If there is no IS and no VALUE, then an attempt will be made to
find the variable defined by NAME. If it exists and is true, the condition
will succeed. Otherwise, it will fail.

=back

=head1 CHILDREN

None

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

  <if name="__PAGE__" OP="!=" VALUE="__LAST_PAGE__">
    ... Children execute if the current page is not the last page ...
  </if>

  <if name="Param1" OP="eq" VALUE="$Param2">
    ... Children execute if Param1 is string-wise equals to Param2 ...
  </if>

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

=cut
