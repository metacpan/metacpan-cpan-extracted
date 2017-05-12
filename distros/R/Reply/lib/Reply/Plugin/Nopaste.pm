package Reply::Plugin::Nopaste;
our $AUTHORITY = 'cpan:DOY';
$Reply::Plugin::Nopaste::VERSION = '0.42';
use strict;
use warnings;
# ABSTRACT: command to nopaste a transcript of the current session

use base 'Reply::Plugin';

use App::Nopaste;


sub new {
    my $class = shift;
    my %opts = @_;

    my $self = $class->SUPER::new(@_);
    $self->{history} = '';
    $self->{service} = $opts{service};

    return $self;
}

sub prompt {
    my $self = shift;
    my ($next, @args) = @_;
    my $prompt = $next->(@args);
    $self->{prompt} = $prompt;
    return $prompt;
}

sub read_line {
    my $self = shift;
    my ($next, @args) = @_;
    my $line = $next->(@args);
    $self->{line} = "$line\n" if defined $line;
    return $line;
}

sub print_error {
    my $self = shift;
    my ($next, $error) = @_;
    $self->{result} = $error;
    $next->($error);
}

sub print_result {
    my $self = shift;
    my ($next, @result) = @_;
    $self->{result} = @result ? join('', @result) . "\n" : '';
    $next->(@result);
}

sub loop {
    my $self = shift;
    my ($continue) = @_;

    my $prompt = delete $self->{prompt};
    my $line   = delete $self->{line};
    my $result = delete $self->{result};

    $self->{history} .= "$prompt$line$result"
        if defined $prompt
        && defined $line
        && defined $result;

    $continue;
}

sub command_nopaste {
    my $self = shift;
    my ($line) = @_;

    $line = "Reply session" unless length $line;

    print App::Nopaste->nopaste(
        text => $self->{history},
        desc => $line,
        lang => 'perl',
        (defined $self->{service}
            ? (services => [ $self->{service} ])
            : ()),
    ) . "\n";

    return '';
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Reply::Plugin::Nopaste - command to nopaste a transcript of the current session

=head1 VERSION

version 0.42

=head1 SYNOPSIS

  ; .replyrc
  [Nopaste]
  service = Gist

=head1 DESCRIPTION

This plugin provides a C<#nopaste> command, which will use L<App::Nopaste> to
nopaste a transcript of the current Reply session. The C<service> option can be
used to choose an alternate service to use, rather than using the one that
App::Nopaste chooses on its own. If arguments are passed to the C<#nopaste>
command, they will be used as the title of the paste.

Note that this plugin should be loaded early in your configuration file, in
order to ensure that it sees all modifications to the result (due to plugins
like [DataDump], etc).

=for Pod::Coverage command_nopaste

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
