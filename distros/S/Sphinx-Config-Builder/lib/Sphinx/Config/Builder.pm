package Sphinx::Config::Builder;

use strict;
use warnings;

our $VERSION = '1.03';

sub new {
    my $pkg  = shift;
    my $self = {
        indexes => [],                                      # container of ::Index references
        sources => [],                                      # container of ::Source references
        indexer => Sphinx::Config::Entry::Indexer->new(),
        searchd => Sphinx::Config::Entry::Searchd->new(),
    };

    bless $self, $pkg;
    return $self;
}

sub push_index {
    my $self = shift;
    push @{ $self->{indexes} }, @_;
    return 1;
}

sub pop_index {
    my $self = shift;
    return pop @{ $self->{indexes} };
}

sub push_source {
    my $self = shift;
    push @{ $self->{sources} }, @_;
    return 1;
}

sub pop_source {
    my $self = shift;
    return pop @{ $self->{sources} };
}

sub index_list {
    my $self = shift;
    return $self->{indexes};
}

sub source_list {
    my $self = shift;
    return $self->{sources};
}

sub indexer {
    my $self = shift;
    return $self->{indexer};
}

sub searchd {
    my $self = shift;
    return $self->{searchd};
}

sub as_string {
    my $self = shift;
    my $ret  = q{};
    foreach my $source ( @{ $self->source_list } ) {
        $ret .= $source->as_string();
    }
    foreach my $index ( @{ $self->index_list } ) {
        $ret .= $index->as_string();
    }
    $ret .= $self->indexer->as_string();
    $ret .= $self->searchd->as_string();
    return $ret;
}

# bless array of singleton key/value hash refs
package Sphinx::Config::Entry;

sub new {
    my $pkg = shift;
    my $self = { kv_pairs => [], };

    bless $self, $pkg;
    return $self;
}

sub kv_push {
    my $self = shift;
    return push @{ $self->{kv_pairs} }, @_;
}

sub kv_pop {
    my $self = shift;
    return pop @{ $self->{kv_pairs} };
}

sub as_string {

}

package Sphinx::Config::Entry::Source;

our @ISA = q{Sphinx::Config::Entry};

sub name {
    my $self = shift;
    $self->{name} = $_[0] if $_[0];
    return $self->{name};
}

sub as_string {
    my $self = shift;
    my $name = $self->{name};
    my $ret  = qq/
source $name 
{ 
/;
    foreach my $kv_pair ( @{ $self->{kv_pairs} } ) {
        my @k = keys %$kv_pair;
        my $k = pop @k;
        my $v = $kv_pair->{$k};
        $ret .= qq{    $k = $v\n};
    }
    $ret .= qq/
}/;
    return $ret;
}

package Sphinx::Config::Entry::Index;

our @ISA = q{Sphinx::Config::Entry};

sub name {
    my $self = shift;
    $self->{name} = $_[0] if $_[0];
    return $self->{name};
}

sub as_string {
    my $self = shift;
    my $name = $self->{name};
    my $ret  = qq/
index $name 
{ 
/;
    foreach my $kv_pair ( @{ $self->{kv_pairs} } ) {
        my @k = keys %$kv_pair;
        my $k = pop @k;
        my $v = $kv_pair->{$k};
        $ret .= qq{    $k = $v\n};
    }
    $ret .= qq/
}/;
    return $ret;
}

package Sphinx::Config::Entry::Indexer;

our @ISA = q{Sphinx::Config::Entry};

sub as_string {
    my $self = shift;
    my $ret  = qq/
indexer 
{ 
/;
    foreach my $kv_pair ( @{ $self->{kv_pairs} } ) {
        my @k = keys %$kv_pair;
        my $k = pop @k;
        my $v = $kv_pair->{$k};
        $ret .= qq{    $k = $v\n};
    }
    $ret .= qq/
}/;
    return $ret;
}

package Sphinx::Config::Entry::Searchd;

our @ISA = q{Sphinx::Config::Entry};

sub as_string {
    my $self = shift;
    my $ret  = qq/
searchd 
{ 
/;
    foreach my $kv_pair ( @{ $self->{kv_pairs} } ) {
        my @k = keys %$kv_pair;
        my $k = pop @k;
        my $v = $kv_pair->{$k};
        $ret .= qq{    $k = $v\n};
    }
    $ret .= qq/
}/;
    return $ret;
}

1;

__END__
=head1 NAME

Sphinx::Config::Builder - Perl extension dynamically creating Sphinx configuration files 
on the fly, using a backend datasource to drive the indexes, sources, and their relationships.

=head1 VERSION

This module is being released as version 1.02.

=head1 SYNOPSIS

	use Sphinx::Config::Builder;
	my $INDEXPATH = q{/path/to/indexes};
	my $XMLPATH   = q{/path/to/xmlpipe2/output};
	
	my $builder = Sphinx::Config::Builder->new();
	
	# %categories may be stored elsewhere, e.g. a .ini file or MySQL database
	my $categories = { cars => [qw/sedan truck ragtop/], boats => [qw/sail row motor/] };
	foreach my $category ( keys %$categories ) {
	    foreach my $document_set ( @{ $categories->{$category} } ) {
		my $xmlfile     = qq{$document_set-$category} . q{.xml};
		my $source_name = qq{$document_set-$category} . q{_xml};
		my $index_name  = qq{$document_set-$category};
		my $src         = Sphinx::Config::Entry::Source->new();
		my $index       = Sphinx::Config::Entry::Index->new();
	
		$src->name($source_name);
		$src->kv_push(
		    { type            => q{xmlpipe} },
		    { xmlpipe_command => qq{/bin/cat $XMLPATH/$xmlfile} },
		);
	
		$builder->push_source($src);
	
		$index->name($index_name);
		$index->kv_push(
		    { source       => qq{$source_name} },
		    { path         => qq{$INDEXPATH/$document_set} },
		    { charset_type => q{utf-8} },
		  );
	
		$builder->push_index($index);
	    }
	}
	$builder->indexer->kv_push( { mem_limit => q{64m} } );
	$builder->searchd->kv_push(
	    { compat_sphinxql_magics => 0 },
	    { listen                 => q{192.168.0.41:9312} },
	    { listen                 => q{192.168.0.41:9306:mysql41} },
	    { log                    => q{/var/log/sphinx/searchd.log} },
	    { query_log              => q{/var/log/sphinx/log/query.log} },
	    { read_timeout           => 30 },
	    { max_children           => 30 },
	    { pid_file               => q{/var/log/sphinx/searchd.pid} },
	    { seamless_rotate        => 1 },
	    { preopen_indexes        => 1 },
	    { unlink_old             => 1 },
	    { workers     => q{threads} },           # for RT to work
	    { binlog_path => q{/var/log/sphinx} },
	);
	
	print $builder->as_string;

This script may now be passed to the Sphinx indexer using the C<--config> option:

 $ indexer --config /path/to/gen_config.pl --all --rotate

=head1 DESCRIPTION

The motivation behind this module is the need to manage many indexes and corresponding sources
handled by a single Sphinx C<searchd> instance.  Managing a configuration file with many indexes
and sources quickly becomes unweildy, and a programatic solution is necessary. Using 
C<Sphinx::Config::Builder>, one may more easily manage Sphinx configurations using a more
appropriate backend (e.g., a simple C<.ini> file or even a  MySQL database). This is particularly
useful if one is frequently adding or deleting indexes and sources. This approach is 
particularly useful for managing non-natively supported Sphinx datasources that might
require the additional step of generating XMLPipe/Pipe2 sources.

This module doesn't read in Sphinx configuration files, it simply allows one
to construct and output a configuration file programmtically.

This module allows one to systematically construct a Sphinx configuration file that
contains so many entries that it is best created dynamically. It's fairly low level,
and provides containers for the following:

=over 4

=item A list of C<Sphinx::Config::Entry::Index> objects, one per C<index> section;

=item A list of C<Sphinx::Config::Entry::Source> objects, one per C<source> section;

=item A singular C<Sphinx::Config::Entry::Indexer> object, one per configuration for C<indexer> options

=item A singular C<Sphinx::Config::Entry::Searchd> object, one per configuration for C<searchd> options

=back

The general idea is that one builds up a list of C<index> sections and corresponding C<source> sections. One
then defines the C<indexer> and C<searchd> options.  One is not bound to specific keywords in each section, meaning
that they may add any key/value pair (as a singleton C<HASH> referece). Each key/value pair corresponds to a
key/value line in each section.

All C<Sphinx::Config::Entry> derived classes implement a C<as_string> method. This method outputs the section
in the format that Sphinx expects. The overall C<Sphinx::Config::Builder> class has a C<as_string> method
that will iterate over all members, calling their C<as_string> method. The result is the full configuration
file that may be printed to STDOUT for the C<indexer> to consume using the C<--config> option.

=head1 SUBROUTINES/METHODS

=head2 C<Sphinx::Config::Builder> 

=head3 C<new>

Highest level constructor.

=head3 C<push_index>

Push a reference of Sphinx::Config::Entry::Index into builder. 

=head3 C<pop_index>

Pop a reference of Sphinx::Config::Entry::Index into builder. 

=head3 C<push_source>

Push a reference of Sphinx::Config::Entry::Source into builder. 

=head3 C<pop_source>

Pop a reference of Sphinx::Config::Entry::Source into builder. 

=head3 C<index_list>

Get container list of all Index references.

=head3 C<source_list>

Get container list of all Source references.

=head3 C<indexer>

Get Sphinx::Config::Entry::Indexer member reference.

=head3 C<sourced>

Get Sphinx::Config::Entry::Searchd member reference.

=head3 C<as_string>

Calls C<as_string> method for all members of the builder object, which results in the entire
configuration file.

=head2 C<Sphinx::Config::Entry::Index> and C<Sphinx::Config::Entry::Source> 

=head3 C<new> 

Constructor.

=head3 C<kv_push> 

Push key/value HASH ref into Index, Source list.

=head3 C<kv_pop> 

Pop key/value HASH ref from Index, Source list.

=head3 C<as_string>

Return string reprentation of Index, Source.

=head3 C<name> 

Set name of Index, Source.

=head2 C<Sphinx::Config::Entry::Indexer> and C<Sphinx::Config::Entry::Searchd>  

=head3 C<new> 

Constructor.

=head3 C<kv_push> 

Push key/value HASH ref into Indexer, Searchd.

=head3 C<kv_pop> 

Pop key/value HASH ref from Indexer, Searchd.

=head3 C<as_string>

Return string representation of Indexer, Searchd.

=head1 DEPENDENCIES

None.

=head1 DIAGNOSTICS

There is no validation, garbage in, garbage out.

=head1 CONFIGURATION AND ENVIRONMENT

None.

=head1 INCOMPATIBILITIES

None.

=head1 BUGS AND LIMITATIONS

Please report - L<https://github.com/estrabd/perl-Sphinx-Config-Builder/issues> 

=head1 AUTHOR

B. Estrade, E<lt>estrabd@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Same terms as Perl itself.
