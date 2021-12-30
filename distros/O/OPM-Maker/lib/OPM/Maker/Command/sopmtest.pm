package OPM::Maker::Command::sopmtest;
$OPM::Maker::Command::sopmtest::VERSION = '1.11';
# ABSTRACT: Check if sopm is valid

use strict;
use warnings;

use Path::Class ();
use OPM::Validate;

use OPM::Maker -command;
use OPM::Maker::Utils qw(check_args_sopm);

sub abstract {
    return "check .sopm if it is valid";
}

sub usage_desc {
    return "opmbuild sopmtest <path_to_sopm>";
}

sub validate_args {
    my ($self, $opt, $args) = @_;

    my $sopm = check_args_sopm( $args, 1 );
    $self->usage_error( 'need path to .sopm' ) if
        !$sopm;
}

sub execute {
    my ($self, $opt, $args) = @_;
    
    my $file = check_args_sopm( $args, 1 );

    if ( !defined $file ) {
        print "No file given!";
        return;
    }
    
    if ( !-f $file ) {
        print "$file does not exist";
        return;
    }

    eval {
        my $content = do{ local (@ARGV, $/) = $file; <> };
        OPM::Validate->validate( $content, 1 );
        1;
    } or do {
        print ".sopm is not valid: $@\n";
        return;
    };
    
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Maker::Command::sopmtest - Check if sopm is valid

=head1 VERSION

version 1.11

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
