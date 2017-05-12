#
# This file is part of TBX-Min
#
# This software is copyright (c) 2016 by Alan Melby.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package TBX::Min;
use strict;
use warnings;
our $VERSION = '0.08'; # VERSION
# ABSTRACT: Read, write and edit TBX-Min files
use subs qw(date_created directionality entries);
use Class::Tiny qw(
    id
    description
    creator
    license
    source_lang
    target_lang
    date_created
    directionality
    entries
);
use XML::Twig;
use autodie;
use Path::Tiny;
use Carp;
use Import::Into;
use DateTime::Format::ISO8601;
use Try::Tiny;
use TBX::Min::TermEntry;
use TBX::Min::LangSet;
use TBX::Min::TIG;
use TBX::Min::NoteGrp;
use TBX::Min::Note;

# Use Import::Into to export subclasses into caller
sub import {
    my $target = caller;
    TBX::Min::TermEntry->import::into($target);
    TBX::Min::LangSet->import::into($target);
    TBX::Min::TIG->import::into($target);
    TBX::Min::NoteGrp->import::into($target);
    TBX::Min::Note->import::into($target);
    return;
}

sub new_from_xml {
    my ($class, $data) = @_;

    if(!$data){
        croak 'missing required data argument';
    }

    my $fh = _get_handle($data);

    # build a twig out of the input document
    my $twig = XML::Twig->new(
        output_encoding => 'UTF-8',
        # do_not_chain_handlers => 1, #can be important when things get complicated
        keep_spaces     => 0,

        # these store new entries, langSets and tigs
        start_tag_handlers => {
            termEntry => \&_termEntryStart,
            langSet => \&_langStart,	#langset
            tig => \&_termGrpStart, #tig
            noteGrp => \&_noteGrpStart, #note group
            note => \&_noteStart, #note
        },

        TwigHandlers    => {
            TBX => \&_check_dialect,
            # header attributes become attributes of the TBX::Min object
            id => \&_headerAtt,
            description => \&_headerAtt,
            dateCreated => \&_date_created,
            creator => \&_headerAtt,
            license => \&_headerAtt,
            directionality => \&_directionality,
            languages => \&_languages,

            # becomes part of the current TBX::Min::TermEntry object
            subjectField => sub {
                shift->{tbx_min_entries}->[-1]->subject_field($_->text)},

            # these become attributes of the current TBX::Min::TIG object
            term => sub {shift->{tbx_min_current_term_grp}->term($_->text)},
            partOfSpeech => sub {
                shift->{tbx_min_current_term_grp}->part_of_speech($_->text)},
            customer => sub {
                shift->{tbx_min_current_term_grp}->customer($_->text)},
            termStatus => sub {
                shift->{tbx_min_current_term_grp}->status($_->text)},

            # these become attributes of the current TBX::Min::Note object
			noteKey => sub {shift->{tbx_min_current_note}->noteKey($_->text)},
			noteValue => sub {shift->{tbx_min_current_note}->noteValue($_->text)},

            # delete the termEntry twig when finished to free up memory
            termEntry => sub {$_[0]->purge},
        }
    );

    # use handlers to process individual tags, then grab the result
    $twig->parse($fh);
    my $self = $twig->{tbx_min_att};
    $self->{entries} = $twig->{tbx_min_entries} || [];
    bless $self, $class;
    return $self;
}

sub _get_handle {
    my ($data) = @_;
    my $fh;
    if((ref $data) eq 'SCALAR'){
        open $fh, '<', $data; ## no critic(RequireBriefOpen)
    }else{
        $fh = path($data)->filehandle('<');
    }
    return $fh;
}


my %valid = map {+($_=>1)} Class::Tiny->get_all_attributes_for(__PACKAGE__);
sub new {
    my ($class, $args) = @_;
    my $self;
    if((ref $args) eq 'HASH'){

        # validate arguments
        if(my @invalids = grep {!$valid{$_}} sort keys %$args){
            croak 'Invalid attributes for class: ' .
                join ' ', @invalids
        }
        if($args->{entries} && ref $args->{entries} ne 'ARRAY'){
            croak q{Attribute 'entries' should be an array reference};
        }
        if(exists $args->{directionality}){
            _validate_dir($args->{directionality});
        }

        # validate datetime and store object, not string
        if(my $dt_string = $args->{date_created}){
            $args->{date_created} = _parse_datetime($dt_string);
        }

        $self = $args;
    }else{
        $self = {};
    }
    $self->{entries} ||= [];
    return bless $self, $class;
}

sub date_created {
    my ($self, $date_created) = @_;
    if($date_created) {
        return $self->{date_created} =
            _parse_datetime($date_created);
    }
    if(my $dt = $self->{date_created}){
        return $dt->iso8601;
    }
    return;
}

sub _parse_datetime {
    my ($dt_string) = @_;
    my $dt;
    try{
        $dt = DateTime::Format::ISO8601->parse_datetime($dt_string);
    }catch{
        croak 'date is not in ISO8601 format';
    };
    return $dt;
}

sub directionality {
    my ($self, $directionality) = @_;
    if(defined $directionality) {
        _validate_dir($directionality);
        return $self->{directionality} = $directionality;
    }
    return $self->{directionality};
}

sub _validate_dir {
    my ($dir) = @_;
    if($dir ne 'bidirectional' and $dir ne 'monodirectional'){
        croak "Illegal directionality '$dir'";
    }
    return;
}

sub entries { ## no critic(RequireArgUnpacking)
    my ($self) = @_;
    if (@_ > 1){
        croak 'extra argument found (entries is a getter only)';
    }
    return $self->{entries};
}

sub add_entry {
    my ($self, $termEntry) = @_;
    if( !$termEntry || !$termEntry->isa('TBX::Min::TermEntry') ){
        croak 'argument to add_entry should be a TBx::Min::TermEntry';
    }
    push @{$self->{entries}}, $termEntry;
    return;
}

sub as_xml {
    my ($self) = @_;

    # construct the whole document using XML::Twig::El's
    my $root = XML::Twig::Elt->new(TBX => {dialect => 'TBX-Min'});
    my $header = XML::Twig::Elt->new('header')->paste($root);

    # each of these header elements is a simple element with text
    for my $header_att (
            qw(id creator license directionality description)){
        next unless $self->{$header_att};
        XML::Twig::Elt->new($header_att,
            $self->{$header_att})->paste(last_child => $header);
    }
    if($self->source_lang || $self->target_lang){
        my @atts;
        push @atts, (source => $self->source_lang) if $self->source_lang;
        push @atts, (target => $self->target_lang) if $self->target_lang;
        XML::Twig::Elt->new(languages => {@atts})->paste(
            last_child => $header)
    }
    if(my $dt = $self->{date_created}){
        XML::Twig::Elt->new(dateCreated => $dt->iso8601)->paste(
            last_child => $header);
    }

    my $body = XML::Twig::Elt->new('body')->paste(last_child => $root);
    for my $termEntry (@{$self->entries}){
        my $entry_el = XML::Twig::Elt->new(
            termEntry => {$termEntry->id ? (id => $termEntry->id) : ()})->
            paste(last_child => $body);
        XML::Twig::Elt->new( '#COMMENT', 'terminological entry')->
            paste(last_child => $entry_el);
        if(my $sf = $termEntry->subject_field){
            XML::Twig::Elt->new(subjectField => $sf)->paste(
                last_child => $entry_el);
        }
        for my $langGrp (@{$termEntry->lang_groups}){
            my $lang_el = XML::Twig::Elt->new(langSet =>
                {$langGrp->code ? ('xml:lang' => $langGrp->code) : ()}
            )->paste(last_child => $entry_el);
            for my $termGrp (@{$langGrp->term_groups}){
                my $term_el = XML::Twig::Elt->new('tig')->paste(
                    last_child => $lang_el);
                XML::Twig::Elt->new( '#COMMENT', 'terminological information group')->
					paste(last_child => $term_el);
                if (my $term = $termGrp->term){
                    XML::Twig::Elt->new(term => $term)->paste(
                        last_child => $term_el);
                }

                if (my $customer = $termGrp->customer){
                    XML::Twig::Elt->new(customer => $customer)->paste(
                        last_child => $term_el);
                }

				for my $noteGrp (@{$termGrp->note_groups}){
					my $note_grp_el = XML::Twig::Elt->new('noteGrp')->paste(
                    last_child => $term_el);

					for my $note (@{$noteGrp->notes}){
						my $note_el = XML::Twig::Elt->new('note')->paste(
                    last_child => $note_grp_el);

						if (my $noteKey = $note->noteKey){
							XML::Twig::Elt->new(noteKey => $noteKey)->paste(
								last_child => $note_el);
						}

						if (my $noteValue = $note->noteValue){
							XML::Twig::Elt->new(noteValue => $noteValue)->paste(
								last_child => $note_el);
						}

					}
                }

                if (my $status = $termGrp->status){
                    XML::Twig::Elt->new(termStatus => $status )->paste(
                        last_child => $term_el);
                }

                if (my $pos = $termGrp->part_of_speech){
                    XML::Twig::Elt->new(partOfSpeech => $pos)->paste(
                        last_child => $term_el);
                }

            } # end tig
        } # end langSet
    } # end termEntry

    # return pretty-printed string
    XML::Twig->set_pretty_print('indented');
    my $TBXmin = \$root->sprint;
	$$TBXmin =~ s/>[\s\t\n]*<!--/><!--/g;  #force comments to be on same line as their parent
	return $TBXmin;
}

######################
### XML TWIG HANDLERS
######################

# croak if the user happened to use the wrong dialect of TBX
sub _check_dialect {
    my (undef, $node) = @_;
    my $type = $node->att('dialect') || 'unknown';
    my $expected = 'TBX-Min';
    if($type ne $expected){
        croak "Input TBX is $type (should be '$expected')";
    }
    return 1;
}

# most of the twig handlers store state on the XML::Twig object.
# A bit kludgy, but it works.

sub _headerAtt {
    my ($twig, $node) = @_;
    $twig->{tbx_min_att}->{_decamel($node->name)} = $node->text;
    return 1;
}

sub _directionality {
    my ($twig, $node) = @_;
    _validate_dir($node->text);
    $twig->{tbx_min_att}->{directionality} = $node->text;
    return 1;
}

sub _date_created {
    my ($twig, $node) = @_;
    $twig->{tbx_min_att}->{date_created} =
        _parse_datetime($node->text);
    return;
}

# turn camelCase into camel_case
sub _decamel {
    my ($camel) = @_;
    $camel =~ s/([A-Z])/_\l$1/g;
    return $camel;
}

sub _languages{
    my ($twig, $node) = @_;
    if(my $source = $node->att('source')){
        ${ $twig->{'tbx_min_att'} }{'source_lang'} = $source;
    }
    if(my $target = $node->att('target')){
        ${ $twig->{'tbx_min_att'} }{'target_lang'} = $target;
    }
    return 1;
}

# add a new termEntry to the list of those found in this file
sub _termEntryStart {
    my ($twig, $node) = @_;
    my $entry = TBX::Min::TermEntry->new();
    if($node->att('id')){
        $entry->id($node->att('id'));
    }else{
        carp 'found termEntry missing id attribute';
    }
    push @{ $twig->{tbx_min_entries} }, $entry;
    return 1;
}

#just set the subject_field of the current termEntry
sub _subjectField {
    my ($twig, $node) = @_;
    $twig->{tbx_min_entries}->[-1]->
        subject_field($node->text);
    return 1;
}

# Create a new langSet, add it to the current termEntry,
# and set it as the current langSet.
sub _langStart {
    my ($twig, $node) = @_;
    my $lang = TBX::Min::LangSet->new();
    if($node->att('xml:lang')){
        $lang->code($node->att('xml:lang'));
    }else{
        carp 'found langSet missing xml:lang attribute';
    }

    $twig->{tbx_min_entries}->[-1]->add_lang_group($lang);
    $twig->{tbx_min_current_lang_grp} = $lang;
    return 1;
}

# Create a new tig, add it to the current langSet,
# and set it as the current tig.
sub _termGrpStart {
    my ($twig) = @_;
    my $term = TBX::Min::TIG->new();
    $twig->{tbx_min_current_lang_grp}->add_term_group($term);
    $twig->{tbx_min_current_term_grp} = $term;
    return 1;
}

# Create a new noteGrp, add it to the current tig,
# and set it as the curren noteGrp.
sub _noteGrpStart {
	my ($twig) = @_;
	my $note_grp = TBX::Min::NoteGrp->new();
	$twig->{tbx_min_current_term_grp}->add_note_group($note_grp);
	$twig->{tbx_min_current_note_grp} = $note_grp;
	return 1;
}

sub _noteStart {
    my ($twig) = @_;
    my $note = TBX::Min::Note->new();
    $twig->{tbx_min_current_note_grp}->add_note($note);
    $twig->{tbx_min_current_note} = $note;
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TBX::Min - Read, write and edit TBX-Min files

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use TBX::Min;
    my $min = TBX::Min->new('/path/to/file.tbx');
    my $entries = $min->entries;
    my $termEntry = TBX::Min::TermEntry->new({id => 'B001'});
    $min->add_entry($termEntry);

=head1 DESCRIPTION

This module allows you to read, write and edit the contents of TBX-Min
data.

C<use>ing this module also automatically C<use>s L<TBX::Min::TermEntry>,
L<TBX::Min::LangSet>, and L<TBX::Min::TIG> via
L<Import::Into>. LangSets contain TIGs(Term Information Groups), termEntries contain
LangSets, and this class contains termEntries. These correspond to the
three levels of information found in TML. You can build up TBX::Min
documents this way and then print them via L</as_xml>. You can also
read an entire TBX-Min XML document for editing via L</new_from_xml>.

=head1 TBX-Min

TBX-Min is a minimal, DCT-style dialect of TBX. It's purpose is to
represent extremely simple termbases, such as spreadsheets, and to
be as human eye-friendly as possible. TBX-Min did not evolve from
any other XML dialect, and so does not have historical artifacts
such as "martif".

DCT stands for "Data Category as Tag Name". Whereas in most TBX
dialects categories such as C<partOfSpeech> are indicated through
attributes, in TBX-Min the tag names represent categories. This
makes for a very readable document. While TBX-Min documents do
conform to TML (Terminological Markup Language) structure, DCT
documents cannot be checked by the
L<TBX-Checker|https://sourceforge.net/projects/tbxutil/>.

If you need more complex or information-rich termbases, we suggest
you use TBX-Basic or even TBX-Default. If you have a TBX-Min document
and would like to upgrade it to TBX-Basic, see L<Convert::TBX::Min>.
Alternatively if you would like to change your TBX-Basic to TBX-Min,
see L<Convert::TBX::Basic>.

=head1 METHODS

=head2 C<new_from_xml>

Creates a new instance of TBX::Min. The single argument should be either a
string pointer containing the TBX-Min XML data or the name of the file
containing this data is required.

=head2 C<new>

Creates a new C<TBX::Min> instance. Optionally you may pass in
a hash reference which is used to initialize the object. The allowed hash
fields are C<id>, C<description>, C<date_created>, C<creator>, C<license>,
C<directionality>, C<source_lang> and C<target_lang>, which correspond to
methods of the same name, and C<entries>, which should be an array reference
containing C<TBX::Min::TermEntry> objects. This method croaks if
C<date_created> is not in ISO 8601 format.

=head2 C<id>

Get or set the document id. This should be a unique string
identifying this glossary.

=head2 C<description>

Get or set the document description.

=head2 C<date_created>

Get or set the the date that the document was created. This should be a
string in ISO 8601 format. This method croaks if C<date_created> is not
in ISO 8601 format.

=head2 C<creator>

Get or set the name of the document creator.

=head2 C<license>

Get or set the document license string.

=head2 C<directionality>

Get or set the document directionality string. This string represents
the direction of translation this document is designed for.

=head2 C<source_lang>

Get or set the code representing the document source language. This should
be ISO 639 and 3166 (e.g. C<en-US>, C<de>, etc.).

=head2 C<target_lang>

Get or set the code representing the document target language. This should
be ISO 639 and 3166 (e.g. C<en-US>, C<de>, etc.).

=head2 C<entries>

Returns an array ref containing the C<TBX::Min::TermEntry> objects contained
in the document.The array ref is the same one used to store the objects
internally, so additions or removals from the array will be reflected in future
calls to this method.

=head2 C<add_entry>

Adds the input C<TBX::Min::TermEntry> object to the list of language groups
contained by this object.

=head2 C<as_xml>

Returns a scalar reference containing an XML representation of this
TBX-Min document. The data is a UTF-8 encoded string.

=head1 CAVEATS

TBX::Min does not as of yet fully validate TBX-Min documents. It is
possible to create non-validating XML via the L<as_xml> method.
This should be fixed in the future.

=head1 SEE ALSO

The following related modules:

=over

=item L<TBX::Min::TermEntry>

=item L<TBX::Min::LangSet>

=item L<TBX::Min::TIG>

=item L<TBX::Min::NoteGrp>

=item L<TBX::Min::Note>

=item L<Convert::TBX::Min>

=item L<Convert::TBX::Basic>

=back

Schema for valiating TBX-Min files are available on
L<GitHub|https://github.com/byutrg/TBX-Spec>.

=head1 AUTHOR

Nathan Glenn <garfieldnate@gmail.com>, James Hayes <james.s.hayes@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Alan Melby.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
