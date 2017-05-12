package Parse::ExCtags;
use Spiffy -Base;
use IO::All;
use vars qw/$VERSION @EXPORT/;
our @EXPORT = qw(exctags);

$VERSION = '0.06';

field file => '';
field tags => [];
field parsed => 0;

sub exctags() {
    new(__PACKAGE__,@_);
}

sub paired_arguments { qw(-file) };

sub new() {
	my $class = shift;
	my $self = {};
	bless $self;
	my ($args) = $self->parse_arguments(@_);
	$self->file($args->{-file} || 'tags');
	$self->parse;
	return $self;
}

sub parse {
	my $forced = shift;
	$self->parsed(0) if $forced;
	return $self->tags if($self->parsed);
	my $tags;
	map { $tags->{$_->{'name'}} = $_ }
        map { 
            $_->[2] =~ s{;"$}{};
            {	name => $_->[0],
		file => $_->[1],
		address => $_->[2],
		field => $self->parse_tagfield($_->[3]), };
	} map $self->split_line($_), (@{io($self->file)});
	$self->parsed(1);
	$self->tags($tags);
}

sub split_line {
    my ($line) = @_;
    if($line =~ /^(.+?)\t(.+?)\t(\/\^.+")\t(.+)?$/) {
        return [$1,$2,$3,$4]
    } else {
        return [split /\t/,$line,4]
    }
}

sub parse_tagfield {
	my $field = shift or return {};
	my $name_re = qr{[a-zA-Z]+};
	my $value_re = qr{[\\a-zA-Z\d]*};
	my $fields;
	for(split(/\t/,$field||=''))  {
		my ($name,$value);
		if(/($name_re):($value_re)/) {
			$name = $1;
			($value) = unescape_value($2);
		} else {
			$name = 'kind';
			$value = lookup_kind($_);
		}
		$fields->{$name} = $value;
	}
	return $fields;
}

sub lookup_kind() {
    my $kind = shift||'';
    return {
	    c => 'class',
	    d => 'define',
	    e => 'enumerator',
	    f => 'function',
	    F => 'file',
	    g => 'enumeration',
	    m => 'member',
	    p => 'function',
	    s => 'structure',
	    t => 'typedef',
	    u => 'union',
	    v => 'variable',
	   }->{$kind} || $kind;
}

sub unescape_value() {
        my @new = @_;
        for(@new) { s{\G(.*?)(\\.)}{$1 . ({'\\t' => chr(9), '\\r' => chr(13), '\\n' => chr(10), '\\\\'  => '\\',}->{$2}||$2)}ge; }
        return @new;
}

=head1 NAME

Parse::ExCtags - Parse ExCtags format of TAGS file

=head1 SYNOPSIS

    use YAML;
    use Parse::ExCtags;
    my $tags = exctags(-file => 'tags')->tags; # hashref
    print YAML::Dump $tags;

=head1 DESCRIPTION

This module exports a exctags() function that returns a
Parse::ExCtags object. The object has a tags() method 
that return an hashref of hashref which are tags
presented in the file given by -file argument.

The key to $tags is the 'tag name'. Usually a subroutine name
or package name. The kind of this 'tag name' is optionally store
in $tags->{field}->{kind}.

Each hash has following keys:

	name:	the tag name
	file:	the associated file
	adddress: the ex pattern to search this tag
	field: tagfields, a hashref of hashref (name,value) pair.

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut



