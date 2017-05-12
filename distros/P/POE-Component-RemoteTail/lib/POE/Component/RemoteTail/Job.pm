package POE::Component::RemoteTail::Job;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $self = bless {@_}, $class;
}

1;

__END__

=head1 NAME

POE::Component::RemoteTail::Job - Job class. 

=head1 SYNOPSIS

  my $job = $tailer->job(
      host        => '127.0.0.1',
      path        => '/home/httpd/logs/access_log',
      user        => 'admin',
      ssh_options => '-i ~/.ssh/identity',
      add_command => '| grep hoge', 
  );

  # $job would be transformed as below.
  # ssh -i ~/.ssh/identity -A 127.0.0.1 "tail -f /home/httpd/access_log | grep hoge"

=head1 DESCRIPTION

=head1 METHOD

=head2 new()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut

