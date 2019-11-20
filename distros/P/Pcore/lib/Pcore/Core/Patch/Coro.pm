package Pcore::Core::Patch::Coro;

use Pcore;
use Coro qw[];

\&Coro::sleep = \&Coro::AnyEvent::sleep;

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Patch::Coro

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
