#line 1
package Test::Spelling;

use 5.006;
use strict;
use warnings;
use Pod::Spell;
use Test::Builder;
use File::Spec;
use File::Temp;
use Carp;

our $VERSION = '0.11';

my $Test        = Test::Builder->new;
my $Spell_cmd   = 'spell';
my $Spell_temp  = File::Temp->new->filename;

sub import {
    my $self = shift;
    my $caller = caller;
    no strict 'refs';
    *{$caller.'::pod_file_spelling_ok'}      = \&pod_file_spelling_ok;
    *{$caller.'::all_pod_files_spelling_ok'} = \&all_pod_files_spelling_ok;
    *{$caller.'::add_stopwords'}             = \&add_stopwords;
    *{$caller.'::set_spell_cmd'}             = \&set_spell_cmd;
    *{$caller.'::all_pod_files'}             = \&all_pod_files
        unless defined &{$caller. '::all_pod_files'};

    $Test->exported_to($caller);
    $Test->plan(@_);
}


my $Pipe_err = 0;

sub pod_file_spelling_ok {
    my $file = shift;
    my $name = @_ ? shift : "POD spelling for $file";

    if ( !-f $file ) {
        $Test->ok( 0, $name );
        $Test->diag( "$file does not exist" );
        return;
    }

    # save digested POD to temp file
    my $checker = Pod::Spell->new;
    $checker->parse_from_file($file, $Spell_temp);

    # run spell command and fetch output
    open ASPELL, "$Spell_cmd < $Spell_temp|" 
        or croak "Couldn't run spellcheck command '$Spell_cmd'";
    my @words = <ASPELL>;
    close ASPELL or die;

    # clean up words, remove stopwords, select unique errors
    chomp for @words;
    @words = grep { !$Pod::Wordlist::Wordlist{$_} } @words;
    my %seen;
    @seen{@words} = ();
    @words = map "    $_\n", sort keys %seen;

    # emit output
    my $ok = !@words;
    $Test->ok( $ok, "$name");
    if ( !$ok ) {
        $Test->diag("Errors:\n" . join '', @words);
    }

    return $ok;
}

sub all_pod_files_spelling_ok {
    my @files = all_pod_files(@_);

    $Test->plan( tests => scalar @files );

    my $ok = 1;
    foreach my $file ( @files ) {
        pod_file_spelling_ok( $file, ) or undef $ok;
    }
    return $ok;
}

sub all_pod_files {
    my @queue = @_ ? @_ : _starting_points();
    my @pod = ();

    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" } @newfiles;

            push @queue, map "$file/$_", @newfiles;
        }
        if ( -f $file ) {
            push @pod, $file if _is_perl( $file );
        }
    } # while
    return @pod;
}

sub _starting_points {
    return 'blib' if -e 'blib';
    return 'lib';
}

sub _is_perl {
    my $file = shift;

    return 1 if $file =~ /\.PL$/;
    return 1 if $file =~ /\.p(l|m|od)$/;
    return 1 if $file =~ /\.t$/;

    local *FH;
    open FH, $file or return;
    my $first = <FH>;
    close FH;

    return 1 if defined $first && ($first =~ /^#!.*perl/);

    return;
}


sub add_stopwords {
    for (@_) {
        my $word = $_;
        $word =~ s/^#?\s*//;
        $word =~ s/\s+$//;
        next if $word =~ /\s/ or $word =~ /:/;
        $Pod::Wordlist::Wordlist{$word} = 1;
    }
}

sub set_spell_cmd {
    $Spell_cmd = shift;
}

1;

__END__

#line 307

