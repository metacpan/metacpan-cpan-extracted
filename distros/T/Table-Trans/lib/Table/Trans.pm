package Table::Trans;
use warnings;
use strict;
use Carp;
use utf8;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/
    add_trans
    get_lang_name
    get_lang_trans
    get_single_trans
    read_trans
    trans_to_json_file
    write_trans
/;
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
our $VERSION = '0.02';

use Table::Readable '0.05', qw!read_table read_table_hash!;
use JSON::Create 'write_json';
use JSON::Parse; # Used for test only in fact.

my %lang2name;

sub add_trans
{
    my ($trans, $file) = @_;
    my $trans2 = read_trans ($file);
    for my $id (keys %$trans2) {
	if ($trans->{$id}) {
	    warn "$file: $id is duplicated.\n";
	}
	else {
	    $trans->{$id} = $trans2->{$id};
	}
    }
}

sub get_single_trans
{
    my ($trans, $id, $lang) = @_;
    if (! $trans->{$id}) {
        croak "Unknown id '$id'";
    }
    if (! $trans->{$id}->{$lang}) {
        carp "Id '$id' has no translation in $lang";
    }
    return $trans->{$id}->{$lang};
}



sub get_lang_trans
{
    my ($trans, $vars, $lang, $verbose) = @_;
    my $varstrans = {};
    for my $id (keys %{$trans}) {
        if ($verbose) {
            print "$id, $trans->{$id}{$lang}\n";
        }
        my $value;
	if ($trans->{$id}{all}) {
	    $value = $trans->{$id}{all};
	}
	else {
	    $value = $trans->{$id}{$lang};
	}
        # The following test checks whether $value is defined because
        # an empty string may be a valid translation (for example if
        # something does not need to be translated).
        if (! defined $value) {
	    if ($verbose) {
		warn "No translation for $id for language $lang: substituting English.";
	    }
            $value = $trans->{$id}->{en};
        }
        $varstrans->{$id} = $value;
    }
    $vars->{trans} = $varstrans;
}




sub get_lang_name
{
    my ($lang) = @_;
    if (scalar (keys %lang2name) == 0) {
	my $l2nfile = __FILE__;
	$l2nfile =~ s!Trans\.pm!l2n.txt!;
	my @langs = read_table ($l2nfile);
	for my $lang (@langs) {
	    $lang2name{$lang->{lang}} = $lang->{name};
	}
    }
    my $name = $lang2name{$lang};
    if (! $name) {
        $name = $lang;
    }
    return $name;
}


sub read_trans
{
    my ($input_file, %options) = @_;
    my ($trans, $order) = read_table_hash ($input_file, 'id', %options);
    x_link ($trans, $order);
    if (wantarray ()) {
        return ($trans, $order);
    }
    return $trans;
}

sub trans_to_json_file
{
    my ($trans_file, $json_file) = @_;
    my $trans = read_trans ($trans_file);
    write_json ($json_file, $trans, indent => 1, sort => 1);
}

sub write_trans
{
    my ($trans, $lang_ref, $file_name, $id_order_ref) = @_;
    if (ref $lang_ref ne 'ARRAY') {
        croak "write_trans requires an array reference of languages to print as its second argument.";
    }
    open my $output, '>:encoding(utf8)', $file_name or die $!;
    my @id_order;
    if ($id_order_ref) {
        @id_order = @{$id_order_ref};
    }
    else {
        warn "No order supplied.\n";
        @id_order = keys %$trans;
    }
    for my $id (@id_order) {
        print $output "id: $id\n";
        for my $lang (@$lang_ref) {
            my $t = $trans->{$id}->{$lang};
            if (! $t) {
                $t = $trans->{$id}->{en};
            }
            if (! $t) {
                croak "Translation $id does not have an English translation.";
            }
            $t =~ s/\s+$//;
            print $output "%%$lang:\n$t\n%%\n";
        }
        print $output "\n";
    }
    close $output;
}

my $x_lang_re = qr/\{\{(\w+)\}\}/;

sub x_link
{
    my ($trans_ref, $order) = @_;
    # X-trans links to copy text from one bit of the translation to another.
    for my $id (@$order) {
        my $trans = $trans_ref->{$id};
        
        for my $lang (keys %$trans) {
            # Check the links go somewhere
            while ($trans->{$lang} =~ /$x_lang_re/g) {
		my $w = $1;
		my $t = $trans_ref->{$w}{all};
		if (! $t) {
		    $t = $trans_ref->{$w}{$lang};
		}
                if (! $t) {
                    die "Bad X-trans {{$w}} in $id for language id '$lang'.\n";
                }
		$trans->{$lang} =~ s/\{\{$w\}\}/$t/g;
            }
        }
    }
}

1;
