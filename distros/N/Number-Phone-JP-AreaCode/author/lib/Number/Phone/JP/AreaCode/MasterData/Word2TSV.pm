package Number::Phone::JP::AreaCode::MasterData::Word2TSV;
use 5.008005;
use strict;
use warnings;
use utf8;

use Class::Accessor::Lite (
    new => 0,
    ro => [qw/agent source_url workdir filename/],
);

use Carp;
use Guard;
use File::Basename;
use File::Spec;
use File::Temp 'tempdir';
use Furl;
use Text::Extract::Word;
use URI;

our $VERSION = "20131201.2";

sub new {
    my ($class, %params) = @_;

    $params{agent}      ||= Furl->new(agent => sprintf('%s/%s', $class, $VERSION));
    $params{source_url} ||= 'http://www.soumu.go.jp/main_content/000157336.doc';

    $params{workdir}  ||= tempdir(CLEANUP => 1);
    $params{filename} = fileparse(URI->new($params{source_url})->path);

    bless { %params }, $class;
}

sub docfile {
    my $self = shift;
    File::Spec->catfile($self->workdir, $self->filename);
}

sub fetch {
    my $self = shift;

    my $res = $self->agent->get($self->source_url);
    croak($res->status_line) unless $res->is_success;

    $res;
}

sub _save_docfile {
    my ($self, $content) = @_;

    my $docfile = $self->docfile;

    my ($fh, $guard) = $self->_openfile('>', $docfile);
    print $fh $content;

    $docfile;
}

sub _openfile {
    my ($self, $mode, $path) = @_; 

    local $Carp::CarpLevel = 1;

    open my $fh, $mode, $path or croak(sprintf('%s - %s', $path, $!));
    my $guard = guard { close $fh };

    ($fh, $guard);
}

sub to_tsv {
    my ($self, $separator) = @_;

    my $res = $self->fetch;
    my $file = $self->_save_docfile($res->content);

    my ($fh, $guard) = $self->_openfile('<', $file);
    
    my $doc = Text::Extract::Word->new($fh);

    my $text = $doc->get_body;

    $text =~ s/(C?D?E)(?:\s+?)(\d)/$1\n$2/g; ### add newline to tail of each records
    $text =~ s/市内局番\t\t/市内局番\n/;     ### separate header and first record
    $text =~ s/\n+/\n/g;                     ### remove white line

    ### suppress strange newline
    $text =~ s/\n([0-9]+)\n/\n$1/g;
    $text =~ s/）\n（/）（/g;

    if ($separator) {
        $text =~ s/\t/$separator/g unless $separator eq "\t";
    }

    $text;
}

1;
__END__

=encoding utf-8

=head1 NAME

Number::Phone::JP::AreaCode::MasterData::Word2TSV - A helper class to extract a master data of area code from a MS-Word file that is distributed by www.soumu.go.jp

=head1 SYNOPSIS

    use Number::Phone::JP::AreaCode::MasterData::Word2TSV;
    my $obj = Number::Phone::JP::AreaCode::MasterData::Word2TSV->new( %options );
    my $tsv_str = $obj->to_tsv( $separator );


=head1 DESCRIPTION

Number::Phone::JP::AreaCode::MasterData::Word2TSV helps to get a MS-Word file from http://www.soumu.go.jp/main_sosiki/joho_tsusin/top/tel_number/shigai_list.html. And, it can export as TSV.

=head1 METHODS

=head2 new

A Constructor Method.

You may pass following options by hash.

=over 4

=item agent

HTTP Client. 

Default is an instance of L<Furl>.

=item source_url

URL for MS-Word file. 

Default is 'http://www.soumu.go.jp/main_content/000157336.doc'.

=item workdir

Working directory for using temporary. (ex: save MS-Word file)

Default is tempdir of L<File::Temp> with CLEANUP => 1.

=back

=head2 to_tsv

It returns TSV formatted master data of area code.

You may specify separator as first argument. Default is hard-tab (\t).

=head1 LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

