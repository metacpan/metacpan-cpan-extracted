package MooseX::CoverableModifiers;

use strict;
BEGIN {
    if ($INC{'Devel/Cover.pm'}) {
        require Devel::Declare;
    }
}

use 5.008_001;
our $VERSION = '0.30';

our ($Declarator, $Offset);

sub skip_declarator {
    $Offset += Devel::Declare::toke_move_past_token($Offset);
}

sub gen_parser {
    my $caller = shift;
    my $cnt = 0;
    sub {
        local ($Declarator, $Offset) = @_;
        my $start = $Offset;
        skip_declarator;
        my $pos = $Offset;
        my $linestr = Devel::Declare::get_linestr();
        while (my $char = substr($linestr, $pos, 1))  {
            return if $char eq '{' || $char eq '&';
            if (substr($linestr, $pos, 2) eq '=>') {
                last;
            }
            ++$pos;
        }
        my ($name) = substr($linestr, $Offset, $pos - $Offset) =~ m/(\w+)/;
        my $modifier_name = "__${Declarator}_${name}_${cnt}";
        substr($linestr, $pos, 2) =
            "=> *$modifier_name =";
        Devel::Declare::set_linestr($linestr);
        ++$cnt;
    }
}

sub import {
    my $class = shift;
    my $caller = caller;

    return unless $INC{'Devel/Cover.pm'};
    Devel::Declare->setup_for(
        $caller,
        { map { $_  => { const => gen_parser($caller) } }
              qw(before around after) }
    );
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

MooseX::CoverableModifiers - Make Moose method modifiers Devel::Cover friendly

=head1 SYNOPSIS

  use Moose;
  use MooseX::CoverableModifiers;

  after foo => sub {
     # this sub is now coverable by Devel::Cover
     # it is actually translated into:
     #   after foo => \&after_foo_0; *after_foo_0 = sub {
  };

=head1 DESCRIPTION

Method modifiers are handy, but they are not L<Devel::Cover> friendly.
This is because Perl makes package-level anonymous subroutines
invisible to L<Devel::Cover>, and the modifiers are often anonymous
subroutines.

MooseX::CoverableModifiers names the subroutines with
L<Devel::Declare>, so they can be seen by L<Devel::Cover> and take
parts in you coverage reports.

The module has no effects unless L<Devel::Cover> is loaded.

=head1 TODO

Some magic tool that uses MooseX::CoverableModifiers for all Moose
classes when you run tests, so you don't even have to explicitly use
the module.

=head1 AUTHOR

Chia-liang Kao E<lt>clkao@clkao.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
