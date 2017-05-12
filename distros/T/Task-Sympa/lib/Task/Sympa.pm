package Task::Sympa;

use strict;
use warnings;

our $VERSION = '1.01';

1;

__END__

=pod

=head1 NAME

Task::Sympa - Sympa dependencies

=head1 VERSION

version 1.01

=head1 SYNOPSIS

This is just a Task module to install dependencies. There's no code to use
or run.

=head1 DESCRIPTION

Installing this module will install all the modules needed for running Sympa
mailing-list manager, ie:

=over

=item * Archive::Zip

=item * CGI

=item * DB_File

=item * DBI

=item * Digest::MD5

=item * Encode

=item * File::Copy::Recursive

=item * HTML::FormatText

=item * HTML::StripScripts::Parser

=item * HTML::TreeBuilder

=item * IO::Scalar

=item * Locale::Messages

=item * Mail::Address

=item * Mail::DKIM

=item * MHonArc::UTF8

=item * MIME::Base64

=item * MIME::Charset

=item * MIME::EncWords

=item * MIME::Lite::HTML

=item * MIME::Tools

=item * Template

=item * Term::ProgressBar

=item * Text::LineFold

=item * Time::HiRes

=item * XML::LibXML

=item * URI::Escap

=back

=head1 AUTHOR

Guillaume Rousse <guillomovitch@cpan.org>

=head1 LICENSE

This software is licensed under the terms of GPLv2+.
