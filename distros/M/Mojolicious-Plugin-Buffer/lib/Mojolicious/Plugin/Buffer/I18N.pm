package Mojolicious::Plugin::Buffer::I18N;

use strict;
use warnings;
use autodie qw(:all);

use Carp qw(croak);
use Exporter qw(import);
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Scalar::Util qw(blessed looks_like_number);
use Sub::Private { mode => 'enforce' };

use version; our $VERSION = version->declare('0.001.0');

# Classes that want the i18n() method import it rather than inheriting it, so
# the plugin keeps Mojolicious::Plugin as its only base class
our @EXPORT_OK = qw(i18n);

# A placeholder is %{name}, or %{name:FORMAT} where FORMAT is a single
# sprintf conversion such as %d or %.1f.  The conversion letters are limited
# so a translated string cannot smuggle in a vector flag or a %n.
Readonly::Scalar my $PLACEHOLDER => qr/(%\{(\w+)(?::(%[-+ 0#]*\d*(?:\.\d+)?[sdufeEgGxXob]))?\})/;

# How deeply variant hashes (gender inside plural, or the reverse) may nest
# before the lookup gives up; it stops a self-referencing catalog looping
Readonly::Scalar my $MAX_VARIANT_DEPTH => 4;

# Input schema for i18n(), shared by the code and the POD
Readonly::Hash my %I18N_SCHEMA => (
	key  => {type => 'string', min => 1},
	args => {type => 'hashref', optional => 1},
);

# The English catalog.  Every user-facing string, error and log line in the
# distribution lives here so that it can be translated or reworded with the
# messages option instead of by editing code.
Readonly::Hash my %MESSAGES => (
	# Programming errors in a caller of i18n() itself
	i18n_key_missing => 'Mojolicious::Plugin::Buffer::I18N: a message key is required',

	# Plugin registration
	options_not_hash => 'Mojolicious::Plugin::Buffer: options must be a hash reference',
	unknown_option => q{Mojolicious::Plugin::Buffer: unknown option '%{option}'},
	option_invalid => 'Mojolicious::Plugin::Buffer: %{option} has an invalid value',
	option_flag => 'Mojolicious::Plugin::Buffer: %{option} must be a true or false value',
	option_optimise_content => 'Mojolicious::Plugin::Buffer: optimise_content must be 0, 1 or 2',
	option_last_modified => 'Mojolicious::Plugin::Buffer: last_modified must be 0, 1, an epoch, a date string or a code reference',
	option_min_compress_size => 'Mojolicious::Plugin::Buffer: min_compress_size must be a non-negative integer',
	option_encodings => 'Mojolicious::Plugin::Buffer: encodings must be an array reference',
	option_compressible_types => 'Mojolicious::Plugin::Buffer: compressible_types must be an array reference',
	option_excluded_types => 'Mojolicious::Plugin::Buffer: excluded_types must be an array reference',
	option_vary_by => 'Mojolicious::Plugin::Buffer: vary_by must be an array reference of header names',
	option_cache_key => 'Mojolicious::Plugin::Buffer: cache_key must be a string or a code reference',
	option_cache => 'Mojolicious::Plugin::Buffer: cache must be an object understanding get(), set() and remove()',
	option_cache_duration => 'Mojolicious::Plugin::Buffer: cache_duration must be a duration',
	option_template_mtime_cache => 'Mojolicious::Plugin::Buffer: template_mtime_cache must be an object understanding get() and set()',
	option_template_mtime_cache_duration => 'Mojolicious::Plugin::Buffer: template_mtime_cache_duration must be a duration',
	option_cache_lock_timeout => 'Mojolicious::Plugin::Buffer: cache_lock_timeout must be a positive number of seconds',
	option_cache_lock => 'Mojolicious::Plugin::Buffer: cache_lock must be an object with acquire() and release() methods',
	option_cache_lock_dir => 'Mojolicious::Plugin::Buffer: cache_lock_dir must be a directory path',
	option_messages => 'Mojolicious::Plugin::Buffer: messages must be a hash reference',
	lock_options_combined => 'Mojolicious::Plugin::Buffer: cache_lock and cache_lock_dir cannot be combined',
	unknown_encoding => q{Mojolicious::Plugin::Buffer: unknown encoding '%{encoding}'},

	# Sent to a client while another request builds the page
	retry_later => "The page is being generated, please try again.\n",

	# File lock backend
	lock_dir_create_failed => q{Mojolicious::Plugin::Buffer: cannot create cache_lock_dir '%{dir}': %{error}},
	lock_dir_not_writable => q{Mojolicious::Plugin::Buffer: cache_lock_dir '%{dir}' is not a writable directory},
	lock_key_undefined => 'cache key is not defined',
	lock_open_failed => 'cannot open %{path}: %{error}',
	lock_failed => 'cannot lock %{path}: %{error}',
	unlock_failed => 'cannot unlock %{path}: %{error}',

	# Redis lock backend
	redis_client_invalid => 'Mojolicious::Plugin::Buffer: cache_lock redis must be an object with an eval() method or a code reference returning one',
	redis_namespace_invalid => 'Mojolicious::Plugin::Buffer: cache_lock namespace must be a non-empty string',
	redis_ttl_invalid => 'Mojolicious::Plugin::Buffer: cache_lock ttl must be a positive number of seconds',
	redis_no_client => 'Redis client factory returned no client',
	redis_no_result => 'Redis lock command returned no result',
	redis_lock_failed => 'Redis lock failed: %{error}',
	redis_unlock_failed => 'Redis unlock failed: %{error}',
	redis_invalid_guard => 'invalid lock guard',

	# Log lines written while serving requests
	log_no_packer => 'Buffer: HTML::Packer is not installed, optimising white space only',
	log_declaration_failed => 'Buffer: %{method} failed: %{error}',
	log_release_failed => 'Buffer: could not release waiting requests: %{error}',
	log_optimised => {
		one => 'Buffer: optimised HTML from %{from} to %{to} byte',
		other => 'Buffer: optimised HTML from %{from} to %{to} bytes',
	},
	log_compressed => {
		one => 'Buffer: compressed with %{encoding} from %{from} to %{to} byte',
		other => 'Buffer: compressed with %{encoding} from %{from} to %{to} bytes',
	},
	log_compress_failed => 'Buffer: %{encoding} compression failed: %{error}',
	log_packer_failed => 'Buffer: HTML::Packer failed: %{error}',
	log_not_modified => 'Buffer: not modified, sending 304',
	log_not_modified_etag => 'Buffer: not modified, sending 304 (ETag %{etag})',
	log_cache_hit => 'Buffer: cache hit for %{key}',
	log_cache_get_failed => 'Buffer: cache get failed: %{error}',
	log_cache_set_failed => 'Buffer: cache set failed: %{error}',
	log_cached => 'Buffer: cached the response for %{key}',
	log_stale_entry => 'Buffer: discarding a cache entry older than the application or its templates',
	log_lock_failed => 'Buffer: shared cache lock failed: %{error}',
	log_unlock_failed => 'Buffer: shared cache unlock failed: %{error}',
	unknown_error => 'unknown error',
	log_building => 'Buffer: this request will build the cache entry for %{key}',
	log_waiting => 'Buffer: waiting for the cache entry for %{key}',
	log_waiting_worker => 'Buffer: waiting for another worker to build the cache entry for %{key}',
	log_gave_up => 'Buffer: gave up waiting for another request to finish',
	log_gave_up_worker => 'Buffer: gave up waiting for another worker',
	log_filled_elsewhere => 'Buffer: another worker filled the cache entry',
	log_not_cached_elsewhere => 'Buffer: the other worker did not cache a response',
	log_finish_waiter_failed => 'Buffer: could not finish a waiting request: %{error}',
	log_flight_expired => 'Buffer: an in-flight response did not finish in time',
	log_serving_waiter => 'Buffer: serving a waiting request from the finished response',
	log_uncacheable_flight => 'Buffer: the in-flight response could not be cached',
	log_mtime_get_failed => 'Buffer: template mtime cache get failed: %{error}',
	log_mtime_set_failed => 'Buffer: template mtime cache set failed: %{error}',
	log_mtime_not_stored => 'Buffer: template mtime cache did not store the scan',
);

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Buffer::I18N - message catalog for Mojolicious::Plugin::Buffer

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

Translate the text that visitors see when the server is busy (an
application using L<Mojolicious::Plugin::Buffer>):

    plugin 'Buffer' => {
	messages => {
	    retry_later => "Die Seite wird erstellt, bitte versuchen Sie es erneut.\n",
	},
    };

Reword a log line, keeping its plural forms.  Give I<every> form, because an
override replaces the whole message:

    plugin 'Buffer' => {
	messages => {
	    log_compressed => {
		one   => 'packed %{from} -> %{to} byte (%{encoding})',
		other => 'packed %{from} -> %{to} bytes (%{encoding})',
	    },
	},
    };

Use a code reference for a language whose plural rules need more than
C<zero>, C<one> and C<other>, such as Polish:

    plugin 'Buffer' => {
	messages => {
	    log_optimised => sub {
		my $args = shift;
		my $n = $args->{count};
		my $word = $n == 1 ? 'bajt'
		    : ($n % 10 >= 2 && $n % 10 <= 4 && ($n % 100 < 10 || $n % 100 >= 20)) ? 'bajty'
		    : 'bajtow';
		return "Buffer: HTML z %{from} do %{to} $word";
	    },
	},
    };

Use the catalog in your own class.  The method reads the overrides from the
C<messages> key of the object:

    package My::Thing;
    use Mojolicious::Plugin::Buffer::I18N qw(i18n);

    sub new { my ($class, %args) = @_; return bless {messages => $args{messages}}, $class }

    my $thing = My::Thing->new(messages => {unknown_option => q{No such option: %{option}}});
    print $thing->i18n('unknown_option', {option => 'wibble'});
    # No such option: wibble

List every key, for example to start a translation:

    my $catalog = Mojolicious::Plugin::Buffer::I18N->catalog;
    print "$_\n" for sort keys %$catalog;

=head1 DESCRIPTION

Every error, warning, log line and client-facing string produced by
L<Mojolicious::Plugin::Buffer> and its lock backends is looked up here by a
I<message key>, so none of them is written into the program logic.  An
application can replace any of them with the C<messages> option of the
plugin, or the C<messages> attribute of a lock backend.

=head2 How it works, in plain words

=over 4

=item 1. The program asks for a message by its key, for example
C<unknown_option>, and passes some values, for example
C<< {option =E<gt> 'wibble'} >>.

=item 2. The object's own C<messages> hash is checked first.  If it has the
key, that text is used.  If not, the built-in English text is used.

=item 3. If the text has several forms (for plural or gender), the right
form is chosen from the C<count> and C<gender> values.

=item 4. Each placeholder, such as C<%{option}>, is replaced by its value.

=item 5. If anything goes wrong (an unknown key, a missing form, a code
reference that dies), the key itself is returned.  So you always see
I<something>, never an empty message.

=back

=head2 Words used in this document

=over 4

=item key

The name of a message, for example C<retry_later>.  Keys are ASCII words.

=item template

The text stored for a key, before placeholders are filled in.

=item placeholder

A marker in a template, written C<%{name}>, that is replaced by a value.

=item variant

One form of a message that has several forms, such as the singular form
C<one> and the plural form C<other>.

=back

=head2 Templates

A template is one of these three things:

=over 4

=item a string

Placeholders are written C<%{name}>, or C<%{name:FORMAT}> where C<FORMAT> is
a single C<sprintf> conversion such as C<%d>, C<%5.1f> or C<%x>.  A
placeholder whose argument was not supplied is left in the text unchanged,
so a missing argument is visible rather than silently blank.  An argument
that is present but undefined becomes the empty string.

=item a hash of variants

Used for plurals and grammatical gender.  The rules are tried in this
order:

=over 4

=item 1. If the C<gender> argument is a key of the hash, that variant is
used.

=item 2. Otherwise, if C<count> is a number: C<zero> is used for 0 and
C<one> for 1, when those keys exist.

=item 3. Otherwise C<other> is used.

=back

Variants may be nested, for example gender variants whose values are plural
variants.  Nesting stops after 4 levels.

=item a code reference

Called with the argument hash.  It returns a string or a hash of variants.
Use it for languages whose plural rules cannot be written with C<zero>,
C<one> and C<other>.  If it dies, the message key is used instead.

=back

=head1 METHODS

=head2 i18n

    my $text = $self->i18n($key, \%args);

=head3 Purpose

Turn a message key and its arguments into text.  It is exported on request
and called as a method, so overrides held by the calling object take
precedence over the English catalog.

=head3 Arguments

=over 4

=item C<$key> (positional, required)

The message key, a non-empty string such as C<'unknown_option'>.

=item C<$args> (positional, optional)

A hash reference of values for the placeholders, plus the optional
selectors C<count> and C<gender>.

=back

=head3 Returns

The text of the message.  For an unknown key the key itself is returned, so
a missing translation never hides that something happened.

=head3 Side effects

None.  If the invocant is a blessed hash with a C<messages> hash, its entries
are consulted first; nothing is written.

=head3 Example

    use Mojolicious::Plugin::Buffer::I18N qw(i18n);

    # Class method: the English catalog
    print __PACKAGE__->i18n('unknown_encoding', {encoding => 'lzma'});
    # Mojolicious::Plugin::Buffer: unknown encoding 'lzma'

    # Plural selection with a sprintf conversion
    my $self = bless {messages => {
	items => {
	    one   => '%{count} item weighs %{kg:%.1f} kg',
	    other => '%{count} items weigh %{kg:%.1f} kg',
	},
    }}, __PACKAGE__;
    print $self->i18n('items', {count => 3, kg => 2.25});
    # 3 items weigh 2.2 kg

=head3 API SPECIFICATION

=head4 Input

    # Params::Get::get_params([qw(key args)], @_) then
    # Params::Validate::Strict::validate_strict
    {
	key  => { type => 'string', min => 1 },
	args => { type => 'hashref', optional => 1 },
    }

=head4 Output

    # Return::Set schema
    { type => 'string' }

=head3 MESSAGES

    Key / Message                             Meaning                         Resolution
    ----------------------------------------  ------------------------------  ----------------------------
    i18n_key_missing                          No key was passed               Pass a message key
      "a message key is required"
    validate_strict: Parameter 'key' ...      The key was empty or not a      Pass a non-empty string key
                                              string
    validate_strict: Parameter 'args' ...     The arguments were not a hash   Pass a hash reference

All three croak.  The last two come from L<Params::Validate::Strict> and are
not translated, because they report a programming error in the caller
rather than a condition a user can act on.

=head3 PSEUDOCODE

    croak if there is no key
    validate key and args
    look the key up in the invocant's overrides, then in the catalog
    if it is not found, return the key
    while the template is a code reference or a hash of variants,
        and the nesting limit has not been reached:
            call the code reference, or pick the variant for gender/count
    if the result is not a plain string, return the key
    replace every %{name} or %{name:FORMAT} whose argument exists
    return the text

=cut

sub i18n {
	my ($self, $key, $args) = @_;

	# The commonest misuse gets its own message; the schema covers the rest
	croak(__PACKAGE__->i18n('i18n_key_missing')) unless defined($key);

	# Positional (key, args) become a hash so the schema can name them
	my $params = validate_strict(
		schema => \%I18N_SCHEMA,
		input => get_params([qw(key args)], $key, $args),
	);
	($key, $args) = ($params->{key}, $params->{args} // {});

	# The invocant's overrides win over the English catalog
	my $overrides = (blessed($self) && ref($self->{messages}) eq 'HASH') ? $self->{messages} : {};
	my $template = exists($overrides->{$key}) ? $overrides->{$key} : $MESSAGES{$key};

	my $text = _select_variant($template, $args);

	# An unknown key, or a template that resolved to nothing usable, is
	# reported by name so the event is never lost
	return defined($text) ? _interpolate($text, $args) : $key;
}

=head2 catalog

    my $messages = Mojolicious::Plugin::Buffer::I18N->catalog;

=head3 Purpose

Return a copy of the English catalog, for translators who want every key
and for tests that check a key exists.

=head3 Arguments

None.

=head3 Returns

A hash reference mapping each message key to its template.  It is a shallow
copy: changing it does not change the catalog.

=head3 Side effects

None.

=head3 Example

    my $catalog = Mojolicious::Plugin::Buffer::I18N->catalog;
    print "$_\n" for sort keys %$catalog;

=head3 API SPECIFICATION

=head4 Input

    # No arguments besides the invocant
    {}

=head4 Output

    # Return::Set schema
    { type => 'hashref', min => 1 }

=head3 MESSAGES

None.

=cut

sub catalog {
	return {%MESSAGES};
}

# Purpose:        Resolve a template to a plain string by following code
#                 references and gender/plural variant hashes.
# Entry criteria: $template is a string, hashref, coderef or undef; $args
#                 is a hashref.
# Exit status:    The selected string, or undef when nothing usable was
#                 found (unknown key, missing variant, dying coderef, or
#                 nesting deeper than $MAX_VARIANT_DEPTH).
# Side effects:   Calls translator-supplied code references.
sub _select_variant :Private {
	my ($template, $args) = @_;

	my $depth = 0;
	while (ref($template) && ($depth++ < $MAX_VARIANT_DEPTH)) {
		if (ref($template) eq 'CODE') {
			# A broken translation must not take the caller down with it
			$template = eval { $template->($args) };
		} elsif (ref($template) eq 'HASH') {
			$template = $template->{_variant_key($template, $args)};
		} else {
			$template = undef;
		}
	}

	return ref($template) ? undef : $template;
}

# Purpose:        Choose which variant of a hash applies to these arguments.
# Entry criteria: $variants is a hashref; $args is a hashref.
# Exit status:    A key of $variants, or 'other' as the fallback.
# Side effects:   None.
sub _variant_key :Private {
	my ($variants, $args) = @_;

	my ($gender, $count) = @{$args}{qw(gender count)};
	my $key = 'other';

	# Gender is checked first so a gendered message can hold plural variants
	if (defined($gender) && exists($variants->{$gender})) {
		$key = $gender;
	} elsif (defined($count) && looks_like_number($count)) {
		$key = 'zero' if ($count == 0) && exists($variants->{zero});
		$key = 'one' if ($count == 1) && exists($variants->{one});
	}

	return $key;
}

# Purpose:        Fill %{name} and %{name:FORMAT} placeholders.
# Entry criteria: $text is a defined string; $args is a hashref.
# Exit status:    The text with every supplied placeholder replaced.
#                 Placeholders with no argument are left as they are.
# Side effects:   None; numeric-format warnings are silenced because a
#                 translated message must never produce a warning itself.
sub _interpolate :Private {
	my ($text, $args) = @_;

	no warnings qw(numeric redundant missing);
	$text =~ s{$PLACEHOLDER}{
		!exists($args->{$2}) ? $1
		: !defined($args->{$2}) ? ''
		: defined($3) ? sprintf($3, $args->{$2})
		: $args->{$2}
	}ge;

	return $text;
}

1;

=head1 COMMON PITFALLS

=over 4

=item * B<An override replaces the whole message; it is not merged.>  If the
built-in message has C<one> and C<other> forms and you override it with a
plain string, both forms are replaced by that one string.  If you override
it with C<< {other =E<gt> '...'} >> only, there is no C<one> form any more.
Give every form you need.

=item * B<undef is not "use the default".>  C<< messages =E<gt>
{retry_later =E<gt> undef} >> makes the message the bare key, so visitors
see the word C<retry_later>.  To go back to the built-in text, I<delete> the
key from the hash instead.

=item * B<A missing argument stays visible.>  C<i18n('unknown_option')>
without C<option> returns C<... unknown option '%{option}'>.  This is on
purpose, so that a mistake shows.  An argument that I<exists> but is undef
becomes the empty string.

=item * B<There is no escape for a literal C<%{name}>.>  If a translated
text must show C<%{word}> itself, do not pass an argument called C<word>.
A plain C<%> that is not followed by C<{> is always left alone.

=item * B<Gender is checked before count.>  With both C<gender> and C<count>
given, a matching gender variant wins.  Put the plural forms I<inside> the
gender variant if you need both.

=item * B<A code reference that dies is silent.>  The key is returned
instead, and no warning is given.  Test your code references.

=item * B<A format is one conversion only.>  C<%{n:%d}> works.  C<%{n:%d%%}>
does not match the placeholder rule and is left in the text unchanged.  The
conversions C<%n> and vector flags are refused on purpose.

=item * B<Messages are chosen once per application.>  The plugin does not
read C<Accept-Language>.  See L</LIMITATIONS>.

=back

=head1 ENCODING

=over 4

=item Templates and arguments

Both may hold any Perl characters: accented letters, any other script, and
emoji.  Use C<use utf8;> in a source file that contains such characters
literally, or write them as escapes like C<"\x{1F600}">.  A C<%{name:%5s}>
width counts characters, not bytes.

=item The returned text

The result is a Perl character string.  It is not encoded.  When you print
it, use a handle with an encoding layer, such as
C<binmode(STDOUT, ':encoding(UTF-8)')>, or Perl warns "Wide character".
L<Mojo::Log> encodes every line to UTF-8 by itself, so log lines are safe.
The plugin encodes the C<retry_later> text to UTF-8 and sends it with
C<charset=UTF-8>.

=item Keys

Keys are matched exactly.  All built-in keys are ASCII; use ASCII for your
own keys too.

=item Messages from Params::Validate::Strict

These are English and are passed through unchanged.

=back

=head1 LIMITATIONS

=over 4

=item * Messages are chosen once per application, not per request.  The
plugin does not negotiate C<Accept-Language>, so the C<retry_later> text sent
with a C<503> is the same for every client.  A per-language reply needs a
custom C<messages> code reference that reads a value the application set.

=item * Plural selection only knows C<zero>, C<one> and C<other>.  Languages
with more categories (Polish, Arabic, Welsh, ...) need a code reference
template.

=item * Messages produced by L<Params::Validate::Strict> for programming
errors (a missing or malformed message key) are passed through in English.

=back

=head1 SEE ALSO

L<Mojolicious::Plugin::Buffer>

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 FORMAL SPECIFICATION

This section describes the catalog in the Z notation, for readers who want
an exact model.  You do not need it to use the module.  C<defaults> is the
built-in English catalog and C<overrides> is the C<messages> hash of the
object the method is called on.

    [KEY, TEXT, NAME, VALUE]

    Args == NAME ⇸ VALUE
    Template ::= str⟨⟨TEXT⟩⟩ | variants⟨⟨NAME ⇸ Template⟩⟩ | code⟨⟨Args → Template⟩⟩

    ┌─ Catalog ───────────────────────────────────
    │ defaults : KEY ⇸ Template
    │ overrides : KEY ⇸ Template
    └─────────────────────────────────────────────

    select : Template × Args × ℕ ⇸ TEXT ∪ {⊥}

    select(t, a, d)           = ⊥                       if d ≥ 4 ∧ t ∉ ran str
    select(str s, a, d)       = s
    select(code f, a, d)      = select(f(a), a, d + 1)  if f(a) does not die
                              = ⊥                       otherwise
    select(variants v, a, d)  = select(v(pick(v, a)), a, d + 1)
                                                        if pick(v, a) ∈ dom v
                              = ⊥                       otherwise

    pick(v, a) = gender a   if gender a ∈ dom v
               = zero       if count a = 0 ∧ zero ∈ dom v
               = one        if count a = 1 ∧ one ∈ dom v
               = other      otherwise

=head2 i18n

C<interpolate> replaces each placeholder C<%{n}> or C<%{n:F}> for which
C<n ∈ dom args?>, and leaves every other placeholder unchanged.

    ┌─ I18n ──────────────────────────────────────
    │ ΞCatalog
    │ key? : KEY ; args? : Args ; text! : TEXT
    ├─────────────────────────────────────────────
    │ key? ≠ ∅
    │ let m == defaults ⊕ overrides •
    │   key? ∈ dom m ∧ select(m key?, args?, 0) ≠ ⊥
    │     ⇒ text! = interpolate(select(m key?, args?, 0), args?)
    │   key? ∉ dom m ∨ select(m key?, args?, 0) = ⊥
    │     ⇒ text! = key?
    └─────────────────────────────────────────────
    -- key? undefined or empty, or args? not a hash: croak

=head2 catalog

    ┌─ Catalog_Copy ──────────────────────────────
    │ ΞCatalog
    │ result! : KEY ⇸ Template
    ├─────────────────────────────────────────────
    │ result! = defaults
    └─────────────────────────────────────────────

=head1 STATE DIAGRAM

This module keeps no state between calls: the catalog never changes while
the program runs, and the overrides belong to the calling object.  So
instead of states, this diagram shows the path one call to L</i18n> takes.
Each box is a step; the text on an arrow is the condition for taking it.

     i18n(key, args)
          |
          v
     +--------------------+  key undef or empty,
     | 1. CHECK ARGUMENTS |  or args not a hash
     |                    | ----------------------> croak
     +--------------------+
          | ok
          v
     +--------------------+  key in neither hash
     | 2. LOOK UP THE KEY | ----------------------> return the key
     | overrides first,   |                         (e.g. "retry_later")
     | then the defaults  |
     +--------------------+
          | found
          v
     +--------------------+  undef template, dying
     | 3. RESOLVE         |  code ref, no variant
     | code ref: call it  |  fits, or 4 levels deep
     | hash: pick variant | ----------------------> return the key
     | repeat until plain |
     +--------------------+
          | plain string
          v
     +--------------------+
     | 4. FILL IN         |  This step cannot fail.  A placeholder
     | %{name} and        |  with no argument is left as it is.
     | %{name:FORMAT}     |
     +--------------------+
          |
          v
     return the text

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

=cut
