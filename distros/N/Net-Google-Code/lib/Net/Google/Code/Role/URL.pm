package Net::Google::Code::Role::URL;
use Any::Moose 'Role';

# requires don't support attribute yet :/
# requires 'project'; 

has 'base_url' => (
    isa     => 'Str',
    is      => 'ro',
    lazy    => 1,
    default => sub { 'http://code.google.com/p/' . $_[0]->project . '/' },
);

has 'base_svn_url' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'http://' . $_[0]->project . '.googlecode.com/svn/' },
);

has 'base_feeds_url' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        'http://code.google.com/feeds/p/' . $_[0]->project . '/'
    },
);

no Any::Moose;

1;

__END__

=head1 NAME

Net::Google::Code::Role::URL - URL Role 


=head1 DESCRIPTION

=head1 INTERFACE

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

