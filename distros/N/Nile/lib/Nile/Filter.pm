#   Copyright Infomation
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author : Dr. Ahmed Amin Elsheshtawy, Ph.D.
# Website: https://github.com/mewsoft/Nile, http://www.mewsoft.com
# Email  : mewsoft@cpan.org, support@mewsoft.com
# Copyrights (c) 2014-2015 Mewsoft Corp. All rights reserved.
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
package Nile::Filter;

our $VERSION = '0.55';
our $AUTHORITY = 'cpan:MEWSOFT';

=pod

=encoding utf8

=head1 NAME

Nile::Filter - Filter functions for Nile framework.

=head1 SYNOPSIS
    
    $filter = $me->filter;
    
    # trim leading and traling spaces
    $str = $filter->trim($str);
    
=head1 DESCRIPTION

Nile::Filter - Filter functions for Nile framework.

=cut

use Nile::Base;
use URI;
use Email::Valid;
use Data::Validate::URI;
use HTML::Entities;
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 trim()
    
    $str = $filter->trim($str);
    @str = $filter->trim(@str);

Remove white spaces from left and right of a string.

=cut

sub trim {
    my ($self) = shift;
    #return if not defined wantarray; # void context
    # /r  - perform non-destructive substitution and return the new value
    return map { s/^\s+|\s+$//gr } @_ if wantarray;
    return shift =~ s/^\s+|\s+$//gr;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 ltrim()
    
    $str = $filter->ltrim($str);
    @str = $filter->ltrim(@str);

Remove white spaces from left of a string.

=cut

sub ltrim {
    my ($self) = shift;
    return map { s/^\s+//gr } @_ if wantarray;
    return shift =~ s/^\s+//gr;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 rtrim()
    
    $str = $filter->rtrim($str);
    @str = $filter->rtrim(@str);

Remove white spaces from right of a string.

=cut

sub rtrim {
    my ($self) = shift;
    return map { s/\s+$//gr } @_ if wantarray;
    return shift =~ s/\s+$//gr;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 trims()
    
    $str = $filter->trims($str);
    @str = $filter->trims(@str);

Remove all white spaces from a string.

=cut

sub trims {
    my ($self) = shift;
    #return if not defined wantarray; # void context
    return map { s/\s+//gr } @_ if wantarray;
    return shift =~ s/\s+//gr;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 strip_html()
    
    $str = $filter->strip_html($str);

Remove all html tags from a string.

=cut

sub strip_html {
    my ($self, $str) = @_;
    $str =~ s/<.+?>//sg;
    #$str =~ s/<[^>]+>//ig;
    return $str;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 disable_html()
    
    $str = $filter->disable_html($str);

Disable all html tags in a string.

=cut

sub disable_html {
    my ($self, $str) = @_;
    HTML::Entities::encode_entities($str, q{<>});
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 escape_html()
    
    $str = $filter->escape_html($str);

Encode entities C< ' " & < > > in string.

=cut

sub escape_html {
    my ($self, $str) = @_;
    HTML::Entities::encode_entities($str, q{'"&<>});
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 strip_script()
    
    # remove <script...>...</script> tags
    $str = $filter->strip_script($str);

Remove script tags from a string.

=cut

sub strip_script {
    my ($self, $str) = @_;
    $str =~ s/<script[^>]*>.*?<\/script>//igs;
    $str;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#s/<script[^>]*>.*?<\/script>//igs;
 #quotemeta  uc   ucfirst lc lc_email uri
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 quotemeta()
    
    $str = $filter->quotemeta($str);

Returns all the ASCII non-"word" characters backslashed.

=cut

sub quotemeta {
    my ($self, $str) = @_;
    quotemeta($str);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 uc()
    
    $str = $filter->uc($str);

Upper case the string letters.

=cut

sub uc {
    my ($self, $str) = @_;
    uc($str);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 lc()
    
    $str = $filter->lc($str);

Lower case the string letters.

=cut

sub lc {
    my ($self, $str) = @_;
    lc($str);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 ucfirst()
    
    $str = $filter->ucfirst($str);

Upper case the first letter in a string.

=cut

sub ucfirst {
    my ($self, $str) = @_;
    ucfirst($str);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 lcfirst()
    
    $str = $filter->lcfirst($str);

Lower case the first letter in a string.

=cut

sub lcfirst {
    my ($self, $str) = @_;
    lcfirst($str);
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 email()
    
    $valid_email = $filter->email('ahmed@email.com');

Returns the valid email or undef if not passed.

=cut

sub email {
    my ($self, $email) = @_;
    $email = CORE::lc($email);
    $email =~s/\s+//g;
    return Email::Valid->address($email) ? $email : undef;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 uri()
    
    $valid_url = $filter->uri('http://www.domain.com/path/file');

Returns the valid url or undef if not passed.

=cut

sub uri {
    my ($self, $uri) = @_;
    $uri =~s/\s+//sg;
    #my $uri = URI->new($uri);
    #return $uri->canonical;
    my $v = Data::Validate::URI->new;
    return $v->is_uri($uri) ? $uri : undef;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 digit()
    
    $digits = $filter->digit($str);

Removes none digits from string and converts to integer.

=cut

sub digit {
    my ($self, $str) = @_;
    $str =~ s/\D+//g;
    $str += 0;
    return $str;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 number()
    
    $str = "data -123.45678";
    $number = $filter->number($str);
    say $number; # -123.45678

Converts string to number.

=cut

sub number {
    my ($self, $str) = @_;
    #if ($str =~ /(\+|-)?([0-9]+(\.[0-9]+)?)/) {
    if ($str =~ /(-)?([0-9]+(\.[0-9]+)?)/) {
        return $1? "$1$2" : $2;
    }
    return;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
=head2 commify()
    
    $number = 12345678;
    $commified = $filter->commify($number);
    say $commified; # 12,345,678

Format numbers with commas nicely for easy reading.

=cut

sub commify {
    my ($self, $str) = @_;
    $str =  reverse $str;
    $str =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $str;
}
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

=pod

=head1 Bugs

This project is available on github at L<https://github.com/mewsoft/Nile>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Nile>.

=head1 SOURCE

Source repository is at L<https://github.com/mewsoft/Nile>.

=head1 SEE ALSO

See L<Nile> for details about the complete framework.

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <mewsoft@cpan.org>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015 by Dr. Ahmed Amin Elsheshtawy احمد امين الششتاوى mewsoft@cpan.org, support@mewsoft.com,
L<https://github.com/mewsoft/Nile>, L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
