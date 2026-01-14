package PApp::EditForm;

##########################################################################
## All portions of this code are copyright (c) 2003,2004 nethype GmbH   ##
##########################################################################
## Using, reading, modifying or copying this code requires a LICENSE    ##
## from nethype GmbH, Franz-Werfel-Str. 11, 74078 Heilbronn,            ##
## Germany. If you happen to have questions, feel free to contact us at ##
## license@nethype.de.                                                  ##
##########################################################################

=head1 NAME

macro/editform - macros used for creating html forms

=head1 SYNOPSIS

 use PApp::EditForm;

=head1 DESCRIPTION

This package lets you create very powerful html forms.

Unless noted otherwise, all the functions creating input elements accept
an optional additional argument which must be a hashref with additional
attribute => value pairs to use in the resulting element (see the similar
functions in L<PApp::HTML>. The C<name> attribute can optionally be
overriden.

=over 4

=cut

use common::sense;
use Carp ();
use Convert::Scalar ();

use PApp;
use PApp::HTML;
use PApp::Exception;
use PApp::SQL;
use PApp::Callback;

use Exporter "import";

our @EXPORT = qw(
   ef_may_edit ef_edit
   ef_field ef_multi_field
   ef_constant
   ef_begin ef_sbegin ef_cbegin ef_mbegin ef_end
   ef_submit ef_reset
   ef_string ef_password
   ef_button ef_hidden ef_text
   ef_checkbox ef_radio ef_selectbox ef_relation
   ef_set ef_enum
   ef_file
   ef_cb_begin ef_cb_end
   ef_form_name
   ef_custom
);

sub __     ($) { $_[0] } #TODO: HACK
sub gettext($) { $_[0] } #TODO: HACK

our $MAX_FORM_FIELD = 1 << 30;

my $EF_KEY;  # key within forms
my $EF_FORM; # key among forms
my $ef_args;
my $ef_key;
my $ef_type;
my $ef_recurse;
my $ef_stateid; # stateid of currently open form
my $ef_form;    # the reference to the form html tag

sub ef_nextid($;$) {
   $EF_KEY or Carp::croak "editform called without outside ef_begin/ef_end calls\n";
   $ef_key = $_[1]{name} ||= $EF_KEY++;
   $ef_args->{"/"}{$ef_key} = $_[0] ? { ref => $_[0] } : { };
   $ef_key;
}

=item ef_mbegin [surl-arguments]

Start an editform. This directive outputs the <form> header (using
C<PApp::multipart_form>). The arguments are treated exactly like
PApp::surl arguments. If it contains callbacks or similar commands, then
these will be executed AFTER the form has been processed.

If, inside C<ef_begin>/C<ef_end>, another form is embedded, the outside
form will automatically be upgraded (sbegin < cbegin < mbegin) to the most
powerful form required by the forms and the nested forms are integrated
into the surrounding form.

Please note that this doesn't work when you change the module, as only the
outside C<ef_begin> call will have the module name honoured, so always use
a C<ef_submit> to do this, or things will go very wrong.

NOTE: editform does not currently check wether a nested form specifies a
module name. Behaviour in this case is undefined, and will most likely
result in an obscure error from surl.

=item ef_sbegin [surl-arguments]

Similar to C<ef_mbegin>, but uses C<PApp::sform> to create the form.

=item ef_cbegin [surl-arguments]

Similar to C<ef_sbegin>, but uses C<PApp::cform> to create the form.

=item ef_begin [surl-arguments]

Identical to C<ef_cbegin>, just for your convenience, as this is the form
most often used.

=item ef_end

Ends the editform. This adds the closing </form> tag.

=cut

sub _ef_parse_begin($) {
   my $ef = shift;

   $ef->{exec} = [];
}

sub _ef_parse_end($) {
   my $ef = shift;

   exists $ef->{"/"}{a}{value}
      or fancydie "form data rejected", "guard field missing (incomplete submit?)";

   &$_ for @{$ef->{cb_begin}};

   my @surlargs;

   for my $field (values %{$ef->{"/"}}) {
      if (exists $field->{submit}) {
         push @surlargs, delete $field->{submit}
            if $field->{submit} && delete $field->{value};
      } elsif (exists $field->{checkbox}) {
         if ($field->{checkbox}) {
            if (delete $field->{value}) {
               ${$field->{ref}} = ${$field->{ref}} |  $field->{checkbox};
            } else {
               ${$field->{ref}} = ${$field->{ref}} & ~$field->{checkbox};
            }
         } else {
            ${$field->{ref}} = ! ! delete $field->{value};
         }
      } elsif (exists $field->{multi}) {
         ${$field->{ref}} = delete $field->{value} || [];
      } elsif (exists $field->{ref}) {
         ${$field->{ref}} = delete $field->{value} if exists $field->{value};
         ${$field->{ref}} = $field->{constant}     if exists $field->{constant};
      }
   }

   PApp::set_alternative $_
      for @surlargs;

   &$_ for @{$ef->{cb_end}};
}

sub _ef_parse_field($$$) {
   my ($field, $data, $charset) = @_;

   if (exists $field->{submit}) {
      $field->{value} = 1;
   } elsif (exists $field->{ref}) {
      if ($charset) {
         $charset = lc $charset;
         if ($charset eq "utf-8") {
            Convert::Scalar::utf8_on $data;
         } elsif ($charset !~ /^(?:|ascii|us-ascii|iso-8859-1)$/) {
            my $pconv = PApp::Recode::Pconv::open PApp::CHARSET, $charset
                           or fancydie "charset conversion from $charset not available";
            $data = Convert::Scalar::utf8_on $pconv->convert($data);
         }
         $data =~ s/\r//g;
      }

      if (exists $field->{map}) {
         $data = $data >= 0 && $data < @{$field->{map}}
               ? $field->{map}[$data]
               : fancydie "form data rejected", "security violation: selectbox value out of range";
      }

      if (exists $field->{multi}) {
         push @{$field->{value}}, $data;

      } elsif (exists $field->{checkbox}) {
         $field->{value} = 1;

      } elsif (exists $field->{password}) {
         $field->{value} = $data
            unless ($data eq "" || $data eq $field->{password});

      } else {
         $field->{value} = $data;
      }
   }
}

sub ef_parse_simple {
   my $ef = shift;

   _ef_parse_begin($ef);

   for my $name (keys %P) {
      if (exists $ef->{"/"}{$name}) {
         my $field = $ef->{"/"}{$name};
         my $data = $P{$name}; #FIXME# was delete $P, but that's not good for debugging#d#
         if (exists $field->{path}) {
            fancydie "file upload widgets are not supported with either ef_sbegin or ef_cbegin/ef_begin, use ef_mbegin instead";
         } else {
            for $data (ref $data ? @$data : $data) {
               $data =~ s/\r//g;
               _ef_parse_field ($field, $data, $state{papp_lcs});
            }
         }
      }
   }
   
   _ef_parse_end($ef);
}

my $ef_parse_s = register_callback {
   $request->query_string ne ""
      or fancydie "missing form data: query string empty";

   &ef_parse_simple;
} name => "papp_ef_s";

my $ef_parse_c = register_callback {
   $request->header_in("Content-Type") eq "application/x-www-form-urlencoded"
      or fancydie "missing form data: application/x-www-form-urlencoded expected, but none found";

   &ef_parse_simple;
} name => "papp_ef_c";

my $ef_parse_m = register_callback {
   my $ef = shift;

   _ef_parse_begin ($ef);
   
   parse_multipart_form {
      my ($fh, $name, $ct, $cta, $cd) = @_;

      if (my $field =  $ef->{"/"}{$name}) {
         if (exists $field->{path}) {
            my $dest;
            my $path = $field->{path};

            # $ct eq "multipart/mixed" then multipart-file-upload
            # would just need to recycle PApp::FormBuffer

            $path = $path->($fh, $name, $ct, $cta, $cd) if ref $path;
            return 0 unless defined $path; # skip unless defined
            if (ref $path) {
               $dest = $path;
               undef $path;
            } else {
               open $dest, ">", "$path~"
                  or return 0;
            }
            my $size = 0;
            my $data;
            while ($fh->read ($data, 256*1024) > 0) {
               $size += syswrite $dest, $data;
            }
            close $dest;
            if ($size > 0) {
               rename "$path~", $path if defined $path;
               # ok if rename worked
            } else {
               unlink "$path~" if defined $path;
               # empty file upload ignored
            }
         } else {
            my $data;
            $fh->read ($data, $MAX_FORM_FIELD);
            $data =~ s/\r\n$//;

            my $charset = $ct =~ /^text\// ? $cta->{charset} : undef;

            _ef_parse_field ($field, $data, $charset);
         }
      } else {
         fancydie "form data rejected", "data received for illegal field '$name'";
      }

      return 1;
   } or fancydie "missing form data: multipart/form-data expected, but none posted";

   _ef_parse_end ($ef);
} name => "papp_ef_m";

sub _ef_begin {
   my $type = pop;
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   if ($ef_recurse && $PApp::stateid == $ef_stateid) {
      $ef_recurse++;
      $ef_type       ||= $type;
      $ef_args->{attr} = { %$attr, %{$ef_args->{attr}} };
      push @{$ef_args->{args}}, @_;

      return "";
   } else {
      $EF_FORM = "a" if $ef_stateid != $PApp::stateid;

      $ef_recurse = 1;
      $ef_stateid = $PApp::stateid;
      $ef_type    = $type;
      $EF_KEY     = "a";
      $ef_args    = {
         attr  => $attr,
         args  => [@_],
      };
      (my $html, $ef_form) = fixup_marker;

      return $html . hidden ef_nextid (\$ef_args->{guard}), "ä";
   }
}

sub ef_sbegin { _ef_begin @_, 1 }
sub ef_cbegin { _ef_begin @_, 2 }
sub ef_mbegin { _ef_begin @_, 4 }

# sub ef_begin* { # hack to get it exported
*ef_begin = *ef_cbegin;

sub ef_end {
   $ef_recurse
      or Carp::croak "ef_end called but no form is open";

   if (--$ef_recurse) {
      "";
   } else {
      my @args = (delete $ef_args->{attr}, @{delete $ef_args->{args}});

      $$ef_form =
         $ef_type & 4 ? multipart_form @args, $ef_parse_m->($ef_args)
       : $ef_type & 2 ? cform          @args, $ef_parse_c->($ef_args)
       : $ef_type & 1 ? sform          @args, $ef_parse_s->($ef_args)
       : Carp::croak "editform: internal error, ef_type is $ef_type";

      # delete $ef_args->{radioref};
      undef $ef_args; # important for database accessors
      undef $EF_KEY;
      (fixup_marker endform)[0];
   }
}

=item ef_edit [group] [DEPRECATED]

Returns wether the global edit-mode is active (i.e. if C<$S{ef_edit}> is
true). If the argument C<group> is given, additionally check for the stated
access right.

=cut

sub ef_edit(;$) {
   $S{ef_edit} and (!@_ or access_p $_[0]);
}

=item ef_may_edit [DEPRECATED]

Display a link that activates or de-activates global edit-mode (see
C<ef_edit>).

=cut

sub ef_may_edit {
   $S{ef_edit}
      ? slink __"[Leave Edit Mode]", ef_edit => undef,
      : slink __"[Enter Edit Mode]", ef_edit => 1;
}

=item ef_submit [\%attrs,] $value [, surl-args...]

Output a submit button. If C<$value> is C<undef> or omitted, __"Save
Changes" is used. The rest of the arguments is interpreted in exactly the
same way as the arguments to C<PApp::surl>, with one exception: if no
destination module is given, the module destination from the C<ef_begin>
macro is used instead of overwriting the destination with the module (as
C<surl> usually does).

The surl-args are interpreted just before callbacks specified via
L<ef_cb_end> (but code references are still executed afterwards unless
C<SURL_EXEC_IMMED> is used).

=item ef_reset [\%attrs,] [$value]

Output a reset button. If C<$value> is omitted, __"Restore Values" is used.

=cut

sub ef_submit {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   my $value = shift;
   defined $value or $value = __"Save Changes";
   my $key = ef_nextid (undef, $attr);
   $ef_args->{"/"}{$key}{submit} = @_ ? &PApp::salternative : undef;
   submit $attr, $key, $value;
}

sub ef_reset {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   reset_button $attr, ef_nextid("reset", $attr), $_[0] || __"Restore Values";
}

=item $name = ef_field fieldref [, name]

This rarely used function does not output an element itself but rather
I<registers> a field name within the editform.  If the name is omitted it
returns a newly generated name. You are responsible for creating an input
element with the given name. Since it doesn't generate an HTML element it
will of course not accept an \%attrs hash.

This can be used to implement custom input elements:

 my $name = ef_field \$self->{value};
 echo tag "input", { name => $name };

=item $name = ef_multi_field fieldref [, name]

Same as C<ef_field> but creates a field that allows multiple
selections, in case you want to create a selectbox.

=item ef_string fieldref, [length=20]

Output a text input field.

=item ef_password fieldref, [length=20, [display]]

Output a non-readable text input field. To ensure that it is not readable,
a C<display> string will be used as value (the reference won't be read),
and the field will be assigned only when the submitted string is non-empty
and different to the C<display> string.

The default C<display> string is the empty string. Whatever you chose for
the display string, it cannot be entered as a valid password (spaces are a
good choice).

=item ef_text fieldref, width, [height]

Output a textarea tag with the given C<width> (if C<height> is omitted
C<ef_text> tries to be intelligent).

=item ef_checkbox fieldref[, bitmask]

Output a checkbox. If C<bitmask> is missing, C<fieldref> is evaluated as a
normal perl boolean. Otherwise, the C<bitmask> is used to set or clear the
given bit in the C<fieldref>.

=item ef_radio fieldref, value

Output a single radiobox that stores, when checked and submitted, "value"
in fieldref. Be careful to use the same fieldref for all radioboxes or
overwrite the name manually. C<fieldref> is compared to "value" using
C<eq>.

=item ef_button fieldref

Output an input button element.

=item ef_hidden fieldref

Output a field of type "hidden" (see also C<ef_constant> for a way to
specify constants that cannot be altered by the client, as C<ef_hidden>
cannot guarentee this).

=cut

sub ef_field {
   return ef_nextid($_[0], { name => $_[1] });
}

sub ef_multi_field {
   my $id = ef_nextid($_[0], { name => $_[1] });
   $ef_args->{"/"}{$id}{multi} = 1;
   return $id;
}

sub ef_string {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   $attr->{size} ||= $_[1]||20;
   textfield $attr, ef_nextid($_[0], $attr), ${$_[0]};
}

sub ef_password {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   $attr->{size} ||= $_[1]||20;
   my $id = ef_nextid($_[0], $attr);
   $ef_args->{"/"}{$id}{password} = "$_[2]";
   password_field $attr, $id, "$_[2]";
}

sub ef_button {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   button $attr, ef_nextid($_[0], $attr), ${$_[0]};
}

sub ef_hidden {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   hidden $attr, ef_nextid($_[0], $attr), ${$_[0]};
}

sub ef_text {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   $attr->{cols} ||= $_[1];
   $attr->{rows} ||= $_[2] > 0
                        ? $_[2]
                        : int (length ${$_[0]} / ($attr->{cols}-5.0001)) - $_[2]
                          + (${$_[0]} =~ y/\n/\n/);
   $attr->{wrap} ||= 'wrap';
   textarea $attr, ef_nextid($_[0], $attr), escape_html ${$_[0]};
}

sub ef_checkbox {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   $attr->{checked} = "checked" if $_[1] ? ${$_[0]} & $_[1] : ${$_[0]};
   my $id = ef_nextid($_[0], $attr);
   $ef_args->{"/"}{$id}{checkbox} = $_[1];
   checkbox $attr, $id;
}

sub ef_radio {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   $attr->{checked} = "checked" if ${$_[0]} eq $_[1];
   $attr->{name} ||= $ef_args->{radioref}{$_[0]};
   my $id = ef_nextid($_[0], $attr);
   $ef_args->{radioref}{$_[0]} = $id;
   radio $attr, $id, $_[1];
}

=item ef_selectbox fieldref, values...

Creates an selectbox for the given values. If $$ref evaluates to
an array-ref, a multiple-select selectbox is created, otherwise a
simple single-select box is used. C<values>... can be as many C<value,
description> pairs as you like.

Beginning with version 0.143 of PApp, C<ef_selectbox> (and other functions
that use it, like C<ef_relation>) don't send the key values to the client,
but instead enumerate them and check wether submitted values are in
range. This has two consequences: first, the client can only submit valid
keys, and second, keys can be complex perl objects (such as C<undef> ;), where
they could only be strings earlier. Only arrayrefs in single-select boxes
need to be treated differently as they will be wrongly interpreted as
multiselects.

Equality of key values (used to find the currently "active" selection) is
done by string comparison after stringifying the keys.

=cut

sub ef_selectbox {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   my $field = shift;
   my $values = @_ > 1 ? \@_ : shift;

   my %content;
   my $content = $$field;

   my $id = ef_nextid $field, $attr;

   if (ARRAY:: eq ref $content) {
      @content{@$content} = ();
      $attr->{multiple} = "multiple";

      $ef_args->{"/"}{$id}{multi} = 1;
   } else {
      $content{$content} = ();
   }

   my $options;
   for (my $i = 0; $i < $#$values; $i += 2) {
      push @{$ef_args->{"/"}{$id}{map}}, $$values[$i];
      $options .= "<option" .
                  (exists $content{$$values[$i]} ? " selected='selected'" : "") .
                  " value='". ($i>>1) ."'>" .
                  (escape_html $$values[$i+1]) .
                  "</option>";
   }

   xmltag "select", $attr, $options;
}

=item ef_relation fieldref, relation, [key => value]...

Output relation, e.g. an selectbox with values from a sql
table. C<relation> is an arrayref containing a string (and optionally
arguments) for a select statement that must output key => value
pairs. The values will be used as display labels in an selectbox and the
corresponding key will be stored in the result field. Examples:

  ef_relation \$field, ["id, name from manufacturer order by 2"];
  ef_relation \$field, ["game_number, game_name 
                         from games where game_name like ?", "A%"];

Additional C<key> => C<value> pairs can be appended and will be used.

=item ef_set fieldref, [ table => "column" ] [mysql-specific]

Similar to C<ef_relation>, but is based on the SQL SET type, i.e. multiple
selections are possible. The field value must be of type "arrayref" for
this to work. Example:

  ef_set \$field, [game => "categories"];

=item ef_enum fieldref, [ table => "column" ] [mysql-specific]

Similar to C<ef_set>, but is based on the ENUM type in sql.

  ef_set \$field, [game => "type"];

=cut

sub ef_relation {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   my ($field, $relation, @values) = @_;
   ref $relation eq "ARRAY" or die __"ef_relation: relation argument must be arrayref";
   unshift @$relation, $PApp::SQL::DBH unless ref $relation->[0];
   my ($dbh, $sel, @arg) = @$relation;
   my $st = sql_uexec $dbh, \my($id,$val), "select $sel", @arg;
   while ($st->fetch) {
      Convert::Scalar::utf8_on $val if Convert::Scalar::utf8_valid $val;
      push @values, $id => $val;
   }
   ef_selectbox $attr, $field, \@values;
}

sub ef_set {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   my ($field, $relation) = @_;
   my ($table, $fild) = @$relation;
   my $st = sql_uexec "show columns from $table like ?", $fild;
   my $type = $st->fetchrow_arrayref->[1];
   $type =~ s/^set\('(.*)'\)$/$1/ or die "ef_set: field '$fild' is not of set type\n";

   ef_selectbox $attr, $field, map {$_, $_} split /','/, $type;
}

sub ef_enum {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   my ($field, $relation) = @_;
   my ($table, $fild) = @$relation;
   my $st = sql_uexec "show columns from $table like ?", $fild;
   my $type = $st->fetchrow_arrayref->[1];
   $type =~ s/^enum\('(.*)'\)$/$1/ or die "ef_enum: field '$fild' is not of enum type\n";

   ef_selectbox $attr, $field, map {$_, $_} split /','/, $type;
}

=item ef_file destination-path[, source-path]

Output a file upload box. The file (if submitted) will be stored as
C<destination-path>. If C<destination-path> is a coderef it will be executed
like this:

   $res = $callback->($fh, $name, $ct, $cta, $cd);

(see C<PApp::parse_multipart_form>, which uses the exact same parameters).
The return value can be undefined, in which case the file will be skipped,
a normal string which will be treated as a path to store the file to or
something else, which will be used as a file-handle.

If a destination path is given, the file will be replaced atomically (by
first writing a file with a prepended "~" and renaming (success case) or
unlinking it).

Although a source path can be given, most browsers will ignore it. Some
will display it, but not use it, so it's a rather useless feature.

C<ef_file> automatically upgrades the surrounding form to a multipart
form.

=cut

sub ef_file {
   my $attr = ref $_[0] eq "HASH" ? shift : {};
   my $id = ef_nextid(undef, $attr);
   $ef_type |= 4;
   $ef_args->{"/"}{$id}{path} = $_[0];
   filefield $attr, $id, $_[1];
}

=item ef_constant fieldref, constant

Set the field to the given C<constant>. This is useful when creating
a database row and some of the fields need to be set to a constant
value. The user cannot change this value in any way. Since this function
doesn't output an html tag it doesn't make sense to prepend an initial
hashref with additonal name => value pairs.

=cut

sub ef_constant {
   my $id = ef_nextid $_[0];
   $ef_args->{"/"}{$id}{constant} = $_[1];
}

=item ef_cb_begin coderef

=item ef_cb_end coderef

Add a callback the is to be called at BEGINing or END of result
processing, i.e. call every BEGIN callback before the form results are
being processed and call every END callback after all form arguments have
been processed (except submit buttons, which are processed after ef_cb_end
callbacks). All callbacks are executed in the order they were registered
(first in, first out).

=cut

sub ef_cb_begin {
   push @{$ef_args->{cb_begin}}, $_[0];
}

sub ef_cb_end {
   push @{$ef_args->{cb_end}}, $_[0];
}

sub ef_cb_end {
   push @{$ef_args->{cb_end}}, $_[0];
}

=item ef_form_name

This function adds a unique C<name="id"> attribute to the opening form tag
and returns the id value to the caller. You can call it as often as you
like. If this function isn't called, no name attribute will be created.

=cut

sub ef_form_name() {
   $ef_args->{attr}{name} ||= $EF_FORM++;
}

sub ef_custom() {
   $EF_KEY++;
}

=back

=head1 SEE ALSO

L<PApp>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://www.goof.com/pcg/marc/

=cut

1
