package Reply::Plugin::Pager;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Pager::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: command to automatically open long results in a pager

use base 'Reply::Plugin';

use Term::ReadKey;


sub new {
    my $class = shift;
    my %opts = @_;

    if (defined $opts{pager}) {
        $ENV{PAGER} = $opts{pager};
    }

    # delay this because it checks $ENV{PAGER} at load time
    require IO::Pager;

    my $self = $class->SUPER::new(@_);
    return $self;
}

sub print_result {
    my $self = shift;
    my ($next, @result) = @_;

    my ($cols, $rows) = GetTerminalSize;

    my @lines = map { split /\n/ } @result;
    if (@lines >= $rows - 2) {
        IO::Pager::open(my $fh) or die "Couldn't run pager: $!";
        $fh->print(@result, "\n");
    }
    else {
        $next->(@result);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Pager - command to automatically open long results in a pager

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [Pager]
  pager = less

=head1 DESCRIPTION

This plugin notices when too much output is going to be displayed as the result
of an expression, and automatically loads the result into a pager instead.

The C<pager> option can be specified to provide a different pager to use,
otherwise it will use the value of C<$ENV{PAGER}>.

=for Pod::Coverage print_result

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
