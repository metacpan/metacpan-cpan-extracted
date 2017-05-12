##
# name:      Stardoc::Module::Perl
# abstract:  Stardoc Perl Module
# author:    Ingy döt Net <ingy@cpan.org>
# copyright: 2011
# license:   perl

package Stardoc::Module::Perl;
use Mouse;
extends 'Stardoc::Module';

use IO::All;
use YAML::XS;

has meta => (
    is => 'ro',
    default => sub {
        {
            markup => 'pod',
            encoding => 'utf8',
        }
    },
);
has other => (
    is => 'ro',
    default => sub {[]},
);
has name => (
    is => 'rw',
);
has synopsis => (
    is => 'rw',
);
has description => (
    is => 'rw',
);
has usage => (
    is => 'rw',
);
has see => (
    is => 'rw',
);
has author => (
    is => 'rw',
);
has copyright => (
    is => 'rw',
);

sub BUILD {
    my ($self) = @_;
    $self->parse();
}

my $pod_re = qr/^=\w+.*?(?:^=cut\s*\n|(?=^=\w)|\z)/ms;
# XXX - Need to account for perlcritic ## at some point.
my $star_re = qr/^##\s.*\n(?:#.*\n)*/m;
my $end_re = qr/^__(?:END|DATA)__.*/ms;

sub parse {
    my ($self) = @_;
    my $text = io($self->file)->all;
    my $sections = $self->sections;
    for ($text =~ /($star_re|$pod_re|$end_re)/g) {
        push @$sections, $self->make_sections($_)
    }
}

sub merge_meta {
    my ($self, $data) = @_;
    my $meta = $self->meta;
    for my $key (keys %$data) {
        my $val = $data->{$key};
        if ($key eq 'author') {
            $meta->{author} = $self->parse_author($val);
        }
        elsif ($key eq 'see') {
            $meta->{see} = ref($val) ? $val : [$val];
        }
        else {
            $meta->{$key} = $data->{$key};
        }
    }
}

sub parse_author {
    my ($self, $val) = @_;
    return [$val] if ref $val eq 'HASH';
    my $list = [ (ref $val eq 'ARRAY') ? @$val : $val ];
    for (my $i = 0; $i < @$list; $i++) {
        if (not ref $list->[$i]) {
            my $string = $list->[$i];
            my $hash = $list->[$i] = {};
            if ($string =~ /^\s*(.*?)\s*<(.*)>$/) {
                $hash->{name} = $1;
                $hash->{email} = $2;
            }
            else {
                $hash->{name} = $val;
            }
        }
    }
    return $list;
}


sub make_sections {
    my ($self, $text) = @_;
    $text =~ s/\s\z/\n/;
    if ($text =~ /^##\s/) {
        return $self->make_comment_sections($text);
    }
    if ($text =~ /^=\w/) {
        $text =~ s/^\s*\n=cut\s*\n/\n/m;
        return $self->make_pod_sections($text);
    }
    if ($text =~ s/^__(END|DATA)__\s\n//) {
        $self->merge_meta;
        return map {
            $self->make_sections($_)
        } ($text =~ /($star_re|$pod_re)/g);
    }
    die $text;
}

sub make_comment_sections {
    my ($self, $text) = @_;
    $text =~ s/^##.*\n//;
    $text =~ s/^# ?//gm;
    my @sections;
    while ($text) {
        $text =~ s/^\s*//;
        if ($text =~ s/(^\w+:\s.*?\n)(\.\.\.\s*\n|\n\s*|\z)//s) {
            push @sections, $self->make_meta_data($1);
        }
        elsif ($text =~ s/^(=\w.*)//s) {
            push @sections, $self->make_pod_sections($1);
        }
        else {
            die;
        }
    }
    return @sections;
}

my $name_re = qr/\S+\s+(NAME|DESCRIPTION|SYNOPSIS)/;
sub make_pod_sections {
    my ($self, $text) = @_;
    my $other = $self->other;
    for my $section ($text =~ /(=\w.*?\n)\s*(?=^=\w|\z)/gms) {
        my $hash = {
            type => 'pod',
            text => $section,
        };
        if ($section =~ $name_re) {
            my $name = lc($1);
            $self->$name($hash);
        }
        else {
            push @$other, $hash;
        }
    }
    return ();       
}

sub make_meta_data {
    my ($self, $text) = @_;
    my $data;
    eval { $data = Load($text) };
    if ($@) {
        warn "Invalid YAML in Stardoc. Skipping section.\n$@";
    }
    $self->merge_meta($data);
    return;
}

1;
