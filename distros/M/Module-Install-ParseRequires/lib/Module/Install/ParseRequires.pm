package Module::Install::ParseRequires;
{
  $Module::Install::ParseRequires::VERSION = '0.002';
}
# ABSTRACT: A Module::Install extension that provides an alternate way to specify dependencies

use strict;
use warnings;

use base qw/ Module::Install::Base /;

require ExtUtils::MakeMaker;
   
sub _parse_requires_method ($) {
    local $_ = shift;
    return 'requires' unless defined;
    if ( ! s/=//g ) {
        s/_*$//;
        $_ .= '_requires' unless m/_?(?:requires|recommends)$/;
    }
    return $_;
}

sub parse_requires {
    my $self = shift;
    my ( $requires, $method );
    if ( @_ > 1 ) {
        $method = _parse_requires_method shift;
    }
    else {
        $method = 'requires';
    }
    $requires = shift;

    for my $line ( split m/\n/, $requires ) {
        s/^\s*//, s/\s*$// for $line;
        if ( $line =~ m/^([\w\=]+):$/ ) {
            $method = _parse_requires_method $1;
        }
        else {
            my ( $dist, $version ) = split m/\s+/, $line, 2;
            $version ||= 0;
            $self->$method( $dist => $version );
        }
    }
}

sub parse_recommends {
    my $self = shift;
    $self->parse_requires( recommends => @_ );
}

1;


=pod

=head1 NAME

Module::Install::ParseRequires - A Module::Install extension that provides an alternate way to specify dependencies

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    # In Makefile.PL

    use inc::Module::Install;
    
    parse_requires build => <<_END_;
    Test::More 1
    _END_

    parse_requires <<_END_;
    DBI
    DBIx::Class 
    Moose
    _END_

=head1 DESCRIPTION

Module::Install::ParseRequires is a L<Module::Install> extension that lets you use a here-document to specify dependencies

=head1 USAGE

=head2 parse_requires $document

Parse $document, treating each line as a space-separated distribution/version combination. If no version is specified, then 0 is assumed (as usual)

    parse_requires <<_END_
    Moose
    Xyzzy 1.02
    JSON 2
    _END_

Is equivalent to:

    requires 'Moose' => 0
    requires 'Xyzzy' => 1.02
    requires 'JSON' => 2

=head2 parse_requires $kind, $document

Parse $document similar to C<parse_requires> above. Instead of calling C<requires> on each dependency, however, the kind of requirement will be inferred from $kind, which can be C<build>, C<test>, etc.

    parse_requires test => <<_END_
    Test::More
    Test::Xyzzy 1.02
    _END_

Is equivalent to:

    test_requires 'Test::More' => 0
    test_requires 'Test::Xyzzy' => 1.02

=head2 parse_recommends $document

Same as C<parse_requires> but does a C<recommend> instead

=head1 SEE ALSO

L<Module::Install>

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

