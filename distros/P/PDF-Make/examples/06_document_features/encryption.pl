#!/usr/bin/perl
# Feature: Encryption
# Description: Demonstrates AES-256 password encryption. The generated PDF
#              requires a password to open. Also shows setting document metadata
#              (title, author) alongside encryption.
# Output: corpus/feature_examples/06_document_features/encryption.pdf

use strict;
use warnings;
use lib 'lib', 'blib/lib', 'blib/arch';
use File::Path qw(make_path);
use PDF::Make::Builder;

make_path('corpus/feature_examples/06_document_features');

my $pdf = PDF::Make::Builder->new(
    file_name => 'corpus/feature_examples/06_document_features/encryption',
);

$pdf->add_page(page_size => 'Letter')
    ->add_h1(text => 'Encrypted Document')
    ->add_text(text => 'This PDF is protected with AES-256 encryption.')
    ->add_text(text => 'Password: "secret"')
    ->add_text(text => '')
    ->add_text(text => 'If you can read this, you entered the correct password.');

# Set up encryption - applied during save()
$pdf->encrypt(
    password  => 'secret',
    algorithm => 'AES-256',
);

$pdf->save();
print "Created corpus/feature_examples/06_document_features/encryption.pdf\n";
print "  Password: secret\n";
