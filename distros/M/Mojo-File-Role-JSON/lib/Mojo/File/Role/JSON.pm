# use strict;
# use warnings;
# package Mojo::File::Role::JSON;

# # ABSTRACT: adds a json method to Mojo::File to store and retrieve JSON

# use Mojo::Base -role;
# use Mojo::Util qw/dumper/;

# use JSON::MaybeXS;
# use Hash::Merge;

# our $pretty = 1;
# our $policy = "die";

# use Want;

# sub json {
#     my $self = shift;
#     if (@_) {
# 	unless (-f $self) { $self->dirname->make_path }
# 	my $json = JSON::MaybeXS->new->pretty($pretty)->utf8->encode(shift());
# 	$self->spew($json);
# 	if (want('OBJECT')) {
# 	    rreturn $self;
# 	} else {
# 	    rreturn $self->json;
# 	}
#     }
#     return undef unless -f $self;

#     # if ($self->policy eq "die") {
#     # 	die sprintf qq(File "%s" not found\n) unless -f $self;
#     # }
#     # elsif ($self->policy eq "undef") {
#     # 	return undef unless -f $self
#     # }
#     # elsif ($self->policy eq "auto") {
#     # 	return {} unless -f $self
#     # }
#     # else {
#     # 	die sprintf qq("%s" is not a valid policy\n), $policy;
#     # }
#     my $json = decode_json $self->slurp;
#     return $json;
# }

# =head2 json

#    my $file = path("foo.json");
#    $file->json({ foo => "bar" }); # stores a variable as json in the file

#    my $foo = $file->json(); # retrieves the decoded variable

# Stores or retrieves vars into the file.

# Returns the stored value or - when dereferenced - the object upon storing.

# Returns the stored value upon retrieving.

# Returns undef if the file does not exist.

# =cut

# sub store {
#     my $self = shift;
#     die "Need something to store\n" unless @_;
#     $self->json(shift())
# }

# sub retrieve {
#     my $self = shift;
#     $self->json();
# }


# sub pretty {
#     my $self = shift;
#     $pretty = shift if @_;
#     return $self;
# }

# sub policy {
#     my $self = shift;
#     $policy = shift if @_;
#     return $self;
# }


# =head2 pretty

#    my $file = path("foo.json")->pretty(1)->json({ foo => "bar" }); #

# Sets the storage to be prettified JSON or not.

# =cut

# sub merge {
#     my ($self, $json, $merger) = @_;
#     $self->json(Hash::Merge::merge $self->json, $json);
# }

# =head2 pretty

#    my $file = path("foo.json");
#    $file->json({ foo => "bar" }); # now {"foo":"bar"}

#    $file->merge({ baz => 12 }); # now {"foo":"bar","baz":12}

# Merges new data and saves it to file.

# =cut

# =head2 do

# Executes a sub with the json content of the file as input, and stores the result back into the file.

# =cut

# sub do {
#     my ($self, $sub) = @_;
#     my $val = sub { local $_ = $self->json; $sub->($_); return $_ }->();
#     $self->json($val);
# }

# 1;

use strict;
use warnings;
package Mojo::File::Role::JSON;

# ABSTRACT: adds a json method to Mojo::File to store and retrieve JSON

use Mojo::Base -role;
use Mojo::Util qw/dumper/;

use JSON::MaybeXS;
use Hash::Merge;

our $pretty = 1;
our $policy = "die";

use Want;


=head1 NAME

Mojo::File::Role::JSON - Adds a json method to Mojo::File to store and retrieve JSON

=head1 SYNOPSIS

    use Mojo::File qw/path/;

    my $file = path("data.json")->with_roles('+JSON');

    # Store JSON
    $file->json({foo => "bar"});

    # Retrieve JSON
    my $data = $file->json;

    # Store with pretty formatting
    $file->pretty(1)->json({foo => "bar"});

    # Merge new data into the existing file
    $file->merge({baz => 42});

    # Run transformation on existing JSON
    $file->do(sub { $_->{hello} = "world" });

=head1 DESCRIPTION

This role adds JSON serialization methods to L<Mojo::File> objects, allowing
them to easily store and retrieve JSON data. It also includes support for merging
and updating JSON content, and optional pretty-printing.

=head1 METHODS

=head2 json

    $file->json({ foo => "bar" }); # stores a variable as JSON in the file

    my $data = $file->json();      # retrieves the decoded JSON from the file

Stores or retrieves JSON data from the file.

=over 4

=item *

When called with an argument, encodes it as JSON and writes it to the file. If the file's parent directory does not exist, it will be created.

=item *

Returns the deserialized data structure when reading.

=item *

If called in object context during storage (e.g. `$file->json(...)`), returns the object.

=item *

Returns undef if the file does not exist when reading.

=back

=cut

sub json {
    my $self = shift;
    if (@_) {
        unless (-f $self) { $self->dirname->make_path }
        my $json = JSON::MaybeXS->new->pretty($pretty)->utf8->encode(shift());
        $self->spew($json);
        if (want('OBJECT')) {
            rreturn $self;
        } else {
            rreturn $self->json;
        }
    }
    return undef unless -f $self;

    my $json = decode_json $self->slurp;
    return $json;
}

=head2 store

    $file->store($data);

Stores the given data structure as JSON into the file. Alias for C<json()> in write mode.

Dies if no data is passed.

=cut

sub store {
    my $self = shift;
    die "Need something to store\n" unless @_;
    $self->json(shift())
}

=head2 retrieve

    my $data = $file->retrieve;

Retrieves and returns the JSON content of the file.

Alias for C<json()> in read mode.

=cut

sub retrieve {
    my $self = shift;
    $self->json();
}

=head2 pretty

    $file->pretty(1);

Enables or disables pretty-printed JSON when writing.

Returns the file object itself.

=cut

sub pretty {
    my $self = shift;
    $pretty = shift if @_;
    return $self;
}

=head2 policy

    $file->policy("die");

Sets the policy for file-not-found handling.

B<Note:> Currently unused, reserved for future use.

=cut

sub policy {
    my $self = shift;
    $policy = shift if @_;
    return $self;
}

=head2 merge

    $file->merge({ bar => 42 });

Merges the provided hash into the current JSON structure in the file and stores the result.

Uses L<Hash::Merge> for merging.

=cut

sub merge {
    my ($self, $json, $merger) = @_;
    $self->json(Hash::Merge::merge $self->json, $json);
}

=head2 do

    $file->do(sub { $_->{count}++ });

Executes a subroutine on the current JSON content.

The sub receives the data structure in C<$_>, and its return value is stored back in the file.

=cut

sub do {
    my ($self, $sub) = @_;
    my $val = sub { local $_ = $self->json; $sub->($_); return $_ }->();
    $self->json($val);
}

1;

=head1 SEE ALSO

L<Mojo::File>, L<JSON::MaybeXS>, L<Hash::Merge>, L<Want>

=head1 AUTHOR

Simone Cesano

This software is copyright (c) 2025 by Simone Cesano.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Simone Cesano.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
