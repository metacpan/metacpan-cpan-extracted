package Pcore::Captcha v1.3.1;

use Pcore -dist, -class;

with qw[Pcore::Util::Result::Status];

has image => ( is => 'ro', isa => ScalarRef, required => 1 );

has phrase         => ( is => 'ro', isa => Bool, default => 0 );    # 1 = captcha has 2-3 words
has case_sensitive => ( is => 'ro', isa => Bool, default => 0 );    # 1 = captcha is case sensitive
has numeric    => ( is => 'ro', isa => Enum [ 0, 1, 2 ],  default => 0 );    # 1 = captcha consists of digits only, 2 = captcha does not contain any digits
has math       => ( is => 'ro', isa => Bool,              default => 0 );    # 1 = arithmetical operation must be performed
has min_length => ( is => 'ro', isa => PositiveOrZeroInt, default => 0 );    # 1..20 = minimum length of captcha text required to input
has max_length => ( is => 'ro', isa => PositiveOrZeroInt, default => 0 );    # 1..20 = maximum length of captcha text required to input
has is_russian => ( is => 'ro', isa => Bool,              default => 0 );    # 1 = captcha goes to Russian Queue

has result => ( is => 'ro', isa => Str, init_arg => undef );

1;
__END__
=pod

=encoding utf8

=cut
