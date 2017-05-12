package Socialtext::WikiFixture;
use strict;
use warnings;
use Test::WWW::Selenium;
use Test::More;

=head1 NAME

Socialtext::WikiFixture - Base class for tests specified on a wiki page

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

  use base 'Socialtext::WikiFixture';

=head1 DESCRIPTION

Socialtext::WikiFixture is a base class that fetches and parses wiki pages
using the Socialtext::Resting REST API.  It then tries to execute the
commands in the wiki tables.  The code for executing the tables should
be implemented in subclasses.

This package assumes that tests will be defined in top level tables on
the specified wiki page.

=head1 FUNCTIONS

=head2 new( %opts )

Create a new fixture object.  You probably mean to call this on a subclass.

=cut

sub new {
    my ($class, %args) = @_;
    my $self = \%args;
    bless $self, $class;

    $self->init;
    $self->setup_table_variables;

    return $self;
}

=head2 init()

Optional initialization hook for subclasses.  Called from new().

=cut

sub init { }

=head2 run_test_table( $table_ref )

Run the commands contained in the supplied table.  The table will
be an array ref of array refs.

=cut

sub run_test_table {
    my $self = shift;
    $self->{table} = shift;

    while (my $row = $self->_next_row) {
        $row->[0] =~ s/^\s*//;
        next unless $row->[0];
        next if $row->[0] =~ /^\*?command\*?$/i; # header

        _escape_options($row);
        $self->handle_command(@$row);
    }

    $self->end_hook;
}

sub _next_row {
    my $self = shift;
    return shift @{ $self->{table} };
}

sub _escape_options {
    my $row = shift;

    for my $cell (@$row) {
        # Trim backticks
        $cell =~ s/^`(.+)`$/$1/;

        # un-escape backticks
        $cell =~ s/^\\`(.+)\\`$/`$1`/;
    }
}

=head2 end_hook()

Optional hook for subclasses that will be called after the tests in the
table have been run.

=cut

sub end_hook {}

=head2 handle_command( @row )

Run the command.  Subclasses can override this.

=cut

sub handle_command {
    my $self = shift;
    my $command = shift;
    $command =~ s/-/_/g;
    die "Bad command for the fixture: ($command)\n"
        unless $self->can($command);

    $self->$command( $self->_munge_options(@_) );
}

sub _munge_options {
    my $self = shift;

    my @opts;
    for (@_) {
        my $var = defined $_ ? $_ : '';
        $var =~ s/%%(\w+)%%/exists $self->{$1} ? $self->{$1} : die "Undef var - '$1'"/eg;
        $var =~ s/\\n/\n/g;
        push @opts, $var;
    }
    return @opts;
}

=head2 setup_table_variables

Called by init() during object creation.  Use it to set variables 
usable by commands in the wiki test tables.

=cut

sub setup_table_variables {
    my $self = shift;
    $self->{start_time} = time;
}

=head2 quote_as_regex( $option )

Will convert an option to a regex.  If qr// is around the option text,
the regex will not be escaped.  Be careful with your regexes.

=cut

sub quote_as_regex {
    my $self = shift;
    my $var = shift || '';

    Encode::_utf8_on($var) unless Encode::is_utf8($var);
    if ($var =~ qr{^qr/(.+?)/([imosx]*)$}) {
        my $mods = $2 || 's';
        return eval "qr/$1/$mods";
    }
    return qr/\Q$var\E/;
}

=head2 include( $page_name )

Include the wiki test table from $page_name into the current table.

It's kind of like a subroutine call.

=cut

sub include {
    my $self      = shift;
    my $page_name = shift;

    print "# Including wikitest commands from $page_name\n";
    my $tp = $self->{testplan}->new_testplan($page_name);

    unshift @{ $self->{table} }, @{ $tp->{table} };
}

=head2 set( $name, $value )

Stores a variable for later use.

=cut

sub set {
    my ($self, $name, $value, $default) = @_;
    unless (defined $name and defined $value) {
        diag "Both name and value must be defined for set!";
        return;
    }

    # Don't set the value if the default flag was passed in
    return if $default and defined $self->{$name};

    $self->{$name} = $value;
    diag "Set '$name' to '$value'";
}

=head2 set_default( $name, $value )

Stores a variable for later use, but only if it is not already set.

=cut

sub set_default { shift->set(@_, 1) }

=head2 comment( $comment )

Prints $comment to test output.

=cut

sub comment {
    my ($self, $comment) = @_;
    diag '';
    diag "comment: $comment";
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-socialtext-editpage at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Socialtext-WikiTest>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Socialtext::WikiFixture

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Socialtext-WikiTest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Socialtext-WikiTest>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Socialtext-WikiTest>

=item * Search CPAN

L<http://search.cpan.org/dist/Socialtext-WikiTest>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
