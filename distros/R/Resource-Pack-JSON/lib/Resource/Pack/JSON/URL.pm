package Resource::Pack::JSON::URL;
BEGIN {
  $Resource::Pack::JSON::URL::VERSION = '0.01';
}
use Moose;

extends 'Resource::Pack::URL';

=head1 NAME

Resource::Pack::JSON::URL - subclass of Resource::Pack::URL to clean up the json2.js souce

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This modifies the install process to strip out the alert that json2.js includes
at the top of the file.

=cut

after install => sub {
    my $self = shift;
    my $installed = $self->install_to_absolute;
    my $contents = $installed->slurp;
    $contents =~ s/^\Qalert('IMPORTANT: Remove this line from json2.js before deployment.');\E\n//;
    my $fh = $installed->openw;
    $fh->print($contents);
    $fh->close;
};

__PACKAGE__->meta->make_immutable;
no Moose;

=head1 AUTHOR

  Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;