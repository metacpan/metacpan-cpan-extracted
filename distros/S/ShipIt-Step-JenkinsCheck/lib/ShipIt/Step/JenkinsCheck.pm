package ShipIt::Step::JenkinsCheck;

use strict;
use warnings;

use base qw/ ShipIt::Step /;
use JSON qw/ decode_json /;
use LWP::UserAgent;
use Try::Tiny;
use ShipIt::Util qw/ $term /;

our $VERSION = '0.01';

sub init {
    my ($self, $conf) = @_;
    $self->{url} = $conf->value('JenkinsCheck.url');
    $self->{jobs} = [ split /,/, $conf->value('JenkinsCheck.jobs') ];

    die "No Jenkins URL specified" unless $self->{url};
    die "No Jenkins jobs specified" unless @{ $self->{jobs} };
    return;
}

# Is really a class method.
sub check_tests {
    my ($self, $jenkins, @jobs) = @_;

    my $ua = LWP::UserAgent->new();
    my $response = $ua->get("$jenkins/api/json");
    die $response->status_line unless $response->is_success;

    my $obj = decode_json($response->decoded_content);

    my %jobs = map { $_->{name} => $_->{color} } @{ $obj->{jobs} };

    my @errors;

    foreach my $j (@jobs) {
        if (!defined($jobs{$j})) {
            push @errors, "$j is not being tested by your Jenkins at $jenkins";
        }
        elsif ($jobs{$j} !~ /^blue|blue_anime$/) {
            push @errors, "$j has status ".$jobs{$j};
        }
    }

    return @errors;
}

sub run {
    my ($self, $state) = @_;
    my @results;

    try {
        @results = $self->check_tests($self->{url}, @{ $self->{jobs} });
    }
    catch {
        my $err = $_;
        while (1) {
            my $line = $term->readline("Jenkins check failed with $err, continue build? (y/n)");
            die "build aborted" if $line =~ /^n/i;
            last if $line =~ /^y/i;
        }
    };

    unless (@results) {
        print "Jenkins reports all your tests to be passing.\n";
        return;
    }

    foreach my $r (@results) {
        print "$r\n";
    }

    while (1) {
        my $line = $term->readline("Jenkins reports trouble, continue build? (y/n)");
        die "build aborted" if $line =~ /^n/i;
        last if $line =~ /^y/i;
    }
    return;
}


1;
__END__

=head1 NAME

ShipIt::Step::JenkinsCheck - Checks your package in your Jenkins CI server before building

=head1 DESCRIPTION

This step checks your project in your Jenkins server, giving you the chance to
abort if the build is currently failing.

=head1 CONFIGURATION

In .shipit config

    JenkinsCheck.url = http://my.jenkins.server:8080
    JenkinsCheck.jobs = job1,job2 ...

=head1 AUTHOR

Dave Lambley, E<lt>davel@state51.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Dave Lambley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
