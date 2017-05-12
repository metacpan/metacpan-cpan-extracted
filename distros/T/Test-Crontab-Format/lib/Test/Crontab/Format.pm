package Test::Crontab::Format;

use 5.008001;
use strict;
use warnings;
use base 'Exporter';

use Test::Builder;
use Parse::Crontab 0.03;

# ABSTRACT: Check crontab format validity

our $VERSION = "0.02";

our @EXPORT = qw(
    crontab_format_ok
);

sub import {
    my $self = shift;
    my $pack = caller;

    my $test = Test::Builder->new;

    $test->exported_to( $pack );
    $test->plan( @_ );

    $self->export_to_level( 1, $self, @EXPORT );
}

sub crontab_format_ok {
    my ($thingy) = @_;

    my $test = Test::Builder->new;

    if( ref $thingy eq 'SCALAR' ){
	if( length ${ $thingy } == 0 ){
	    $test->ok( 0, "scalar content" );
	    $test->diag("content is empty");
	}
	else{
	    my $crontab = Parse::Crontab->new( content => ${ $thingy }, verbose => 0 );
	    if( $crontab->is_valid ){
		$test->ok( 1, "crontab format: scalar content" );
	    }
	    else{
		$test->ok( 0, "scalar content" );
#		$test->diag( $crontab->error_messages );
	    }
	}
    }
    else{
	my $file = $thingy;
	if( not -f $file or not -r $file ){
	    $test->ok( 0, $file );
	    $test->diag( sprintf "file '%s' not readable", $file );
	}
	elsif( -z $file ){
	    $test->ok( 0, $file );
	    $test->diag( sprintf "file '%s' is empty", $file );
	}
	else{
	    my $crontab = Parse::Crontab->new( file => $file, verbose => 0 );
	    if( $crontab->is_valid ){
		$test->ok( 1, sprintf "crontab format: %s", $file );
	    }
	    else{
		$test->ok( 0, $file );
#		$test->diag( $crontab->error_messages );
	    }
	}
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Test::Crontab::Format - Check crontab format validity

=head1 SYNOPSIS

    use Test::Crontab::Format;

    crontab_format_ok("etc/crontab.txt");
    crontab_format_ok( \ $content );

=head1 DESCRIPTION

Test::Crontab::Format checks your crontab format is valid or not.

=head1 FUNCTIONS

=over 4

=item B<crontab_format_ok>

Checks the validity. You can pass file name or scalar ref.

=back

=head1 NOTE

passing empty (0 byte) file/content always yields failure despite Parse::Crontab treats it as success.

=head1 DEPENDENCY

Parse::Crontab

=head1 SEE ALSO

example/crontab_format.t

=head1 REPOSITORY

https://github.com/ryochin/p5-test-crontab-format

=head1 AUTHOR

Ryo Okamoto E<lt>ryo@aquahill.netE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) Ryo Okamoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
