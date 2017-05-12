package Module::Install::ORLite2Pod;

use 5.006001;
use strict;
use warnings;
use Module::Install::Base ();
use Params::Util;
use ORLite::Pod;

our @ISA     = qw(Module::Install::Base);
our $VERSION = '1.000';
$VERSION =~ s/_//ms;

sub orlite2pod {
    my $self = shift;
    return if not $Module::Install::AUTHOR;

    my ( $from, $to, $author, $email, $year ) = @_;

    #die unless things are defined?

    unless ( -d $to ) {
        die("Failed to find $to directory");
    }
    unshift @INC, $to;

    unless ( Params::Util::_CLASS($from) ) {
        usage();
    }
    eval "use $from { show_progress => 1 };";
    if ($@) {
        die("Failed to load $from: $@");
    }

    my $generator = ORLite::Pod->new(
        trace  => 1,
        from   => $from,
        to     => $to,
        author => $author,
        email  => $email,
        year   => $year
    );

    $generator->run;

    return 1;
} ## end sub orlite2pod

1;
__END__

=encoding utf-8

=head1 NAME

Module::Install::ORLite2Pod - Updates the Pod for an ORLite generated distribution.

=head1 SYNOPSIS

  # in Makefile.PL
  use inc::Module::Install;
  orlite2pod('My::Project::DB', 'lib', 'Adam Kennedy', 'adamk@cpan.org', '2009');

=head1 DESCRIPTION

Module::Install::ORLite2Pod is a Module::Install plugin to
automatically update the Pod for ORLite modules 'make dist'.


=head1 AUTHOR

Sven Dowideit E<lt>sdowideit@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Module::Install|Module::Install>

=cut
