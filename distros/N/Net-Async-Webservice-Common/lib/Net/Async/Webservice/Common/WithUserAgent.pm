package Net::Async::Webservice::Common::WithUserAgent;
$Net::Async::Webservice::Common::WithUserAgent::VERSION = '1.0.2';
{
  $Net::Async::Webservice::Common::WithUserAgent::DIST = 'Net-Async-Webservice-Common';
}
use Moo::Role;
use Net::Async::Webservice::Common::Types qw(AsyncUserAgent);
use namespace::autoclean;
use 5.010;

# ABSTRACT: user_agent attribute, sync or async


has user_agent => (
    is => 'ro',
    isa => AsyncUserAgent,
    required => 1,
    coerce => AsyncUserAgent->coercion,
);

around BUILDARGS => sub {
    my ($orig,$class,@args) = @_;

    my $ret = $class->$orig(@args);

    if (ref $ret->{loop} && !$ret->{user_agent}) {
        require Net::Async::HTTP;
        $ret->{user_agent} = Net::Async::HTTP->new();
        $ret->{loop}->add($ret->{user_agent});
    }

    return $ret;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::Common::WithUserAgent - user_agent attribute, sync or async

=head1 VERSION

version 1.0.2

=head1 SYNOPSIS

 package My::WS::Client {
  use Moo;
  with 'Net::Async::Webservice::Common::WithUserAgent';
 }

 use IO::Async::Loop;

 my $loop = IO::Async::Loop->new;

 my $c_with_default_async_ua = My::WS::Client->new({
   loop => $loop,
 });


 my $async_ua = Net::Async::HTTP->new();
 $loop->add($async_ua);

 my $c_with_custom_async_ua = My::WS::Client->new({
   user_agent => $async_ua,
 });


 my $sync_ua = LWP::UserAgent->new();

 my $c_with_custom_async_ua = My::WS::Client->new({
   user_agent => $sync_ua,
 });

=head1 DESCRIPTION

This role provides a C<user_agent> attribute, guaranteed to work
mostly like a L<Net::Async::HTTP>. If a L<LWP::UserAgent>-like object
is passed in, L<Net::Async::Webservice::Common::SyncAgentWrapper> is
used to wrap it. You can also pass the C<loop> constructor parameter
to get a default L<Net::Async::HTTP> instance.

=head1 ATTRIBUTES

=head2 C<user_agent>

A user agent object, looking either like L<Net::Async::HTTP> (has
C<do_request>, C<GET>, and C<POST>) or like L<LWP::UserAgent> (has
C<request>, C<get>, and C<post>).

=head1 METHODS

=head2 C<BUILDARGS>

=head2 C<new>

As you can see in the L</SYNOPSIS>, you can construct objects of classes consuming this role is a few different ways:

 $class->new({
   user_agent => $async_ua,
 });

will just set the L</user_agent>.

 $class->new({ loop => $loop });

will construct a L<Net::Async::HTTP>, set it as L</user_agent>, and
register it to the loop.

 $class->new({
   user_agent => $sync_ua,
 });

will set the L</user_agent> to an instance of
L<Net::Async::Webservice::Common::SyncAgentWrapper> wrapping the
C<$sync_ua>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
