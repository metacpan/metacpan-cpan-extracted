package Qstruct;

use strict;
use Carp;

use Qstruct::Array;

our $VERSION = '0.100';

require XSLoader;
XSLoader::load('Qstruct', $VERSION);



my $reverse_type_lookup = {
  1 => { name => 'string', width => 16, },
  2 => { name => 'blob', width => 16, },
  3 => { name => 'bool', },
  4 => { name => 'float', width => 4, },
  5 => { name => 'double', width => 8, },
  6 => { name => 'int8', width => 1, },
  7 => { name => 'int16', width => 2, },
  8 => { name => 'int32', width => 4, },
  9 => { name => 'int64', width => 8, },
};

sub type_lookup {
  my $type = shift;

  my $info = $reverse_type_lookup->{$type & 0xFFFF};

  my $name = $info->{name};

  $name = "u$name" if $type & (1<<16);

  return ($name, $info->{width});
}



sub _install_closure {
  no strict 'refs';
  *{$_[0]} = $_[1];
}


sub load_schema {
  my $spec;

  if (@_ == 1) {
    $spec = shift;
  } elsif (@_ == 2 && $_[0] eq __PACKAGE__) {
    ## Qstruct->load_schema is common mis-use, allow anyway
    $spec = pop;
  } else {
    croak "load_schema needs 1 argument (the schema)";
  }

  Qstruct::parse_schema($spec)->iterate(sub {
    my $def = shift;

    my $body_size = $def->{body_size};

    _install_closure("$def->{name}::build", sub {
      return bless { i => 0, b => Qstruct::Builder->new(0, $body_size, 1), }, "$_[0]::Builder";
    });

    _install_closure("$def->{name}::encode", sub {
      my $params = $_[1];
      my $elems = ref($params) eq 'HASH' ? 1 : scalar(@$params);

      my $builder = bless { i => 0, b => Qstruct::Builder->new(0, $body_size, $elems), }, "$_[0]::Builder";

      if (ref($params) eq 'HASH') {
        foreach my $key (keys %$params) {
          $builder->$key($params->{$key});
        }
      } else {
        for my $i (0 .. ($elems-1)) {
          $builder->{i} = $i;
          foreach my $key (keys %{ $params->[$i] }) {
            $builder->$key($params->[$i]->{$key});
          }
        }
      }

      return $builder->encode;
    });

    _install_closure("$def->{name}::decode", sub {
      my $ret = Qstruct::Runtime::sanity_check($_[1]);
      croak "malformed qstruct, sanity ($ret)"
        if $ret;
      return bless { i => 0, e => \$_[1], }, "$_[0]::Loader";
    });

    _install_closure("$def->{name}::Builder::encode", sub {
      return $_[0]->{b}->render;
    });

    for(my $i=0; $i < $def->{num_items}; $i++) {
      my $item = Qstruct::Definitions::get_item($def->{def_addr}, $i);

      my $setter_name = "$def->{name}::Builder::$item->{name}";
      my $getter_name = "$def->{name}::Loader::$item->{name}";

      my $type = $item->{type};
      my $nested_type = $item->{nested_type};
      my ($full_type_name, $type_width) = type_lookup($type);
      my $base_type = $type & 0xFFFF;
      my $fixed_array_size = $item->{fixed_array_size};
      my $is_unsigned = $type & (1<<16);
      my $is_array_fix = $type & (1<<17);
      my $is_array_dyn = $type & (1<<18);

      my $byte_offset = $item->{byte_offset};
      my $bit_offset = $item->{bit_offset};

      my $type_getter_sub_name = "Qstruct::Runtime::get_$full_type_name";
      my $type_getter_sub = \&$type_getter_sub_name;
      my $type_setter_method = "set_$full_type_name";

      if ($is_array_dyn) {
        if ($base_type == 1 || $base_type == 2) { # string/blob
          my $alignment = $base_type == 1 ? 1 : 8;
          _install_closure($setter_name, sub {
            my $elems = scalar @{$_[1]} || return;
            my $builder = Qstruct::Builder->new(0, 16, $elems);
            for my $i (0 .. ($elems - 1)) {
              $builder->set_string(0, $i * 16, $_[1]->[$i], $alignment);
            }
            $_[0]->{b}->set_string($_[0]->{i}, $byte_offset, $builder->render, 8);
            return $_[0];
          });

          _install_closure($getter_name, sub {
            my $buf = $_[0]->{e};
            my $body_index = $_[0]->{i};
            Qstruct::Runtime::get_string($$buf, $body_index, $byte_offset, my $str);
            my ($magic_id, $body_size, $elems) = @{ Qstruct::Runtime::unpack_header($str) };

            return Qstruct::ArrayRef->new($elems,
                             sub {
                               return undef if $_[0] >= $elems;
                               Qstruct::Runtime::get_string($str, $_[0], 0, exists $_[1] ? $_[1] : my $o);
                               return $o if !exists $_[1];
                             });
          });
        } elsif ($base_type == 10) { # nested qstruct
          _install_closure($setter_name, sub {
            return if !scalar @{ $_[1] };
            my $nested_val = $nested_type->encode($_[1]);
            $_[0]->{b}->set_string($_[0]->{i}, $byte_offset, $nested_val, 8);
            return $_[0];
          });

          _install_closure($getter_name, sub {
            my $buf = $_[0]->{e};
            my $parent_i = $_[0]->{i};

            my ($magic_id, $body_size, $elems);

            {
              my $nested_obj = bless { e => \'', }, "${nested_type}::Loader";
              Qstruct::Runtime::get_string($$buf, $_[0]->{i}, $byte_offset, ${$nested_obj->{e}});
              ($magic_id, $body_size, $elems) = @{ Qstruct::Runtime::unpack_header(${$nested_obj->{e}}) };
            }

            return Qstruct::ArrayRef->new($elems,
                             sub {
                               return undef if $_[0] >= $elems;

                               my $nested_obj = bless { i => $_[0], e => \'', }, "${nested_type}::Loader";
                               Qstruct::Runtime::get_string($$buf, $parent_i, $byte_offset, ${$nested_obj->{e}});

                               my $ret = Qstruct::Runtime::sanity_check(${$nested_obj->{e}});
                               croak "malformed qstruct, sanity ($ret)"
                                 if $ret;

                               $_[1] = $nested_obj;
                               return $nested_obj;
                             });
          });
        } elsif ($base_type >= 4 && $base_type <= 9) { # floats and ints
          _install_closure($setter_name, sub {
            my $elems = scalar @{$_[1]} || return;
            my $builder = Qstruct::Builder->new(0, $type_width, $elems);
            for my $i (0 .. ($elems - 1)) {
              $builder->$type_setter_method($i, 0, $_[1]->[$i]);
            }
            $_[0]->{b}->set_string($_[0]->{i}, $byte_offset, $builder->render, 8);
            return $_[0];
          });

          _install_closure($getter_name, sub {
            my $buf = $_[0]->{e};
            my $body_index = $_[0]->{i};
            Qstruct::Runtime::get_string($$buf, $body_index, $byte_offset, my $str);
            my ($magic_id, $body_size, $elems) = @{ Qstruct::Runtime::unpack_header($str) };
            return Qstruct::ArrayRef->new($elems,
                             sub {
                               return undef if $_[0] >= $elems;
                               return $type_getter_sub->($str, $_[0], 0);
                             });
          });
        } else {
          croak "dynamic arrays of type $base_type/$type not supported";
        }
      } elsif ($is_array_fix) {
        if ($base_type >= 4 && $base_type <= 9) { # floats and ints
          _install_closure($setter_name, sub {
            if (ref $_[1]) {
              my $elems = scalar @{$_[1]} || return;
              croak "$item->{name} is a fixed array of ${full_type_name}[$fixed_array_size] but you passed in an array of $elems values"
                if $elems != $fixed_array_size;

              for (my $i=0; $i<$elems; $i++) {
                $_[0]->{b}->$type_setter_method($_[0]->{i}, $byte_offset + ($i * $type_width), $_[1]->[$i]);
              }
            } else {
              my $total_size = $fixed_array_size * $type_width;
              croak "$item->{name} is a fixed array of $total_size bytes but you provided " . length($_[1]) . " bytes"
                if length($_[1]) != $total_size;
              $_[0]->{b}->set_raw_bytes($_[0]->{i}, $byte_offset, $_[1]);
            }
            return $_[0];
          });

          _install_closure($getter_name, sub {
            my $buf = $_[0]->{e};
            my $body_index = $_[0]->{i};
            return Qstruct::ArrayRef->new($fixed_array_size,
                             sub {
                               return undef if $_[0] >= $fixed_array_size;
                               return $type_getter_sub->($$buf, $body_index, $byte_offset + ($_[0] * $type_width));
                             }, sub {
                               Qstruct::Runtime::get_raw_bytes($$buf, $body_index, $byte_offset, $fixed_array_size * $type_width, $_[0]);
                             });
          });
        } else {
          croak "fixed arrays of type $base_type/$type not supported";
        }
      } else { ## scalar
        if ($base_type == 1 || $base_type == 2) { # string/blob
          my $alignment = $base_type == 1 ? 1 : 8;
          _install_closure($setter_name, sub {
            $_[0]->{b}->set_string($_[0]->{i}, $byte_offset, $_[1], $alignment);
            return $_[0];
          });

          _install_closure($getter_name, sub {
            Qstruct::Runtime::get_string(${$_[0]->{e}}, $_[0]->{i}, $byte_offset, exists $_[1] ? $_[1] : my $o);
            return $o if !exists $_[1];
          });
        } elsif ($base_type == 10) { # nested qstruct
          my $alignment = 8;
          _install_closure($setter_name, sub {
            my $nested_val = $nested_type->encode($_[1]);
            $_[0]->{b}->set_string($_[0]->{i}, $byte_offset, $nested_val, $alignment);
            return $_[0];
          });

          my $empty_struct = "\x00"x12 . "\x01\x00\x00\x00";

          _install_closure($getter_name, sub {
            my $nested_obj = bless { i => 0, e => \'', }, "${nested_type}::Loader";
            Qstruct::Runtime::get_string(${$_[0]->{e}}, $_[0]->{i}, $byte_offset, ${$nested_obj->{e}});
            $nested_obj->{e} = \$empty_struct if length(${$nested_obj->{e}}) == 0;
            my $ret = Qstruct::Runtime::sanity_check(${$nested_obj->{e}});
            croak "malformed qstruct, sanity ($ret)"
              if $ret;
            return $nested_obj;
          });
        } elsif ($base_type == 3) { # bool
          _install_closure($setter_name, sub {
            $_[0]->{b}->set_bool($_[0]->{i}, $byte_offset, $bit_offset, $_[1] ? 1 : 0);
            return $_[0];
          });

          _install_closure($getter_name, sub {
            Qstruct::Runtime::get_bool(${$_[0]->{e}}, $_[0]->{i}, $byte_offset, $bit_offset);
          });
        } elsif ($base_type >= 4 && $base_type <= 9) { # floats and ints
          _install_closure($setter_name, sub {
            $_[0]->{b}->$type_setter_method($_[0]->{i}, $byte_offset, $_[1]);
            return $_[0];
          });

          _install_closure($getter_name, sub {
            $type_getter_sub->(${$_[0]->{e}}, $_[0]->{i}, $byte_offset);
          });
        } else {
          croak "unknown type: $base_type/$type";
        }
      }
    }
  });
}




1;


__END__

=encoding utf-8

=head1 NAME

Qstruct - Qstruct perl interface

=head1 SYNOPSIS

    use Qstruct;

    Qstruct::load_schema(q{
      ## This is my schema

      qstruct MyPkg::PhoneNumber {
        number @0 string;
        ext @1 uint8;
      }

      qstruct MyPkg::User {
        id @0 uint64;
        name @1 string;

        is_admin @3 bool;
        is_moderator @4 bool;

        emails @2 string[];
        account_ids @5 uint64[];
        phones @7 MyPkg::PhoneNumber[];

        sha256_hash @6 uint8[32];
      }

    });

    ## Build a new user message:
    my $message = MyPkg::User->encode({
                    name => "jimmy",
                    id => 100,
                    is_admin => 1,
                    emails => [ 'jimmy@example.com', 'jim@jimmy.com' ],
                    sha256_hash => "\xFF"x32,
                    phones => [
                                { number => '555-1212' },
                                { number => '1234567', ext => 2 },
                              ],
                  });

    ## Load a user message:
    my $user = MyPkg::User->decode($message);

    ## Scalar accessors:
    print "User id: " . $user->id . "\n";
    print "User name: " . $user->name . "\n";
    print "*** ADMIN ***\n" if $user->is_admin;
    print "1st phone #: " . $user->phones->[0]->number . "\n";

    ## Zero-copy access to strings/blobs:
    $user->name(my $name);

    ## Zero-copy array iteration:
    $user->emails->foreach(sub {
      print "EMAIL is ", $_[0], "\n";
    });

    ## Zero-copy nested qstructs:
    $user->phones->foreach(sub {
      $_[0]->number(my $number);
      print $number, "\n";
    });


=head1 DESCRIPTION

B<Qstruct> is a binary serialisation format that requires a schema. This documentation describes the L<Qstruct> perl module which is the reference dynamic-language implementation for qstructs. The specification for the qstruct format is documented here: L<Qstruct::Spec>.

Because in qstructs the "wire" and "in-memory" formats are the same, the C<encode> and C<decode> functions are somewhat mis-named. As soon as the object is built in memory it is ready to be copied out to disk or the network. Also, as soon as it is read or mapped into memory it is ready for accessing. So the C<encode> and C<decode> operations are mostly no-ops.

This module is designed to be particularly efficient for reading qstructs. Numerics, strings, blobs, nested qstructs, and arrays of these types can all be randomly-accessed or iterated over without reading or parsing any unrelated parts of the message (qstructs are B<lazy>). Furthermore, all copies of message data can be avoided -- only pointers into the message memory are recorded (qstructs are B<zero-copy>).

The encoder in this module is not exactly slow, it just does more memory-allocations and copying than an optimised implementation would. The compiled static interface will probably be optimised for encoding eventually.



=head1 ZERO-COPY

As shown in the synopsis, fields can be accessed simply by calling their corresponding methods on the objects representing decoded messages:

    ## Field access (copying)

    my $name = $user->name;

However, due to the semantics of return values in perl, the above line of code allocates new memory and copies the C<name> field into it. This is inefficient for two reasons.

Firstly, the process of copying takes time. This time is proportional to how large the data is. Often this copying is unnecessary and therefore an inefficient use of time.

Secondly, copying is inefficient because impacts your memory system. If you aren't copying the data, you aren't paging it in from disk, pulling it into your filesystem/CPU caches, pushing other things out of cache, or exercising your CPU's translation lookaside buffer (TLB).

Qstruct is always lazy when it comes to memory access: It will only access the bare-minimum memory required to fulfill accessor requests.

If you wish to avoid copying however, you need to pass an "output scalar" into the accessor method:

    ## Field access (zero-copy)

    $user->name(my $name);

Passing these output scalars into methods to avoid copying is a common theme throughtout the L<Qstruct> perl module interface.

This module is designed to work with modules like L<File::Map> which map files into perl strings without actually copying them into memory, and also with modules like L<LMDB_File> which interact with transactional in-process databases that support zero-copy. When combining Qstructs with these modules you can have true zero-copy access to a filesystem or database from your high-level perl code just as conveniently as with copying interfaces.

For more information on zero-copy, see the L<Test::ZeroCopy> module and the C<t/zerocopy.t> test in this distribution that uses it.


=head1 ARRAYS

When you call the accessor method on an array it returns a special overloaded object of type C<Qstruct::ArrayRef>. This object can (obviously) be accessed as an array reference:

    ## Array random access (copying)

    my $first_email = $user->emails->[0];

Because of the lazy-loading nature of Qstructs, in the above code none of the other emails are accessed at all. If the message is in a memory-mapped file, the other emails might never even get paged in to memory (although emails are generally small enough that they many of them can be stored together on the same page).

Of course references can also be de-referenced and iterated over:

    ## Array iteration (copying)

    foreach my $email (@{ $user->emails }) {
      print "Email: ", $email, "\n";
    }

The problem with the above approach is that while the elements are lazy-loaded, they are not zero-copy. In other words, for the elements iterated over, perl is allocating new memory for them and then they are being copied into it.

In addition to acting as array refs, C<Qstruct::ArrayRef> objects are also special objects with additional methods. The C<get> method is similar to the random-access de-reference operation above except that you can pass an output scalar to it to get zero-copy behaviour:

    ## Array random access (zero-copy)

    $user->emails->get(0, my $first_email);

Because the C<my $first_email> scalar is passed in, the C<get> method will populate it with a pointer into the underlying message-memory owned by the C<$user> object.

There is also a C<len> method which of course means you can iterate over arrays:

    ## Array iteration (zero-copy)

    my $emails = $user->emails;

    for(my $i=0; $i < $emails->len; $i++) {
      $emails->get($i, my $email);
      print "Email: ", $email, "\n";
    }

There is a short-cut C<foreach> method that simplifies the above pattern:

    ## Array iteration short-cut (zero-copy)

    $user->emails->foreach(sub {
      print "Email: ", $_[0], "\n";
    });

Arrays of qstructs work essentially the same as arrays of primitive types except that the elements are decoded objects convenient for traversal, ie:

    ## Arrays of qstructs
    $department->staff->employees->foreach(sub {
      my $employee = shift;
      print "Employee id: ", $employee->id, "\n";
      print "Employee name: ", $employee->name, "\n";
    });



=head1 RAW ARRAY ACCESS

For fixed arrays of numeric types there are also raw accessors. For example, hash values are known-length values so it can make sense for them to be fixed arrays which are inlined in the message body for efficiency (see L<Qstruct::Spec> for details). Such arrays are most likely best accessed with raw accessors:

    ## Whole-array access (copying)

    my $hash_value = $user->sha256_hash->raw;

Of course there is a corresponding zero-copy interface:

    ## Whole-array access (zero-copy)

    $user->sha256_hash->raw(my $hash_value);

When encoding messages, you can simply pass in an appropriately sized string and it will be treated as raw:

    my $msg = MyPkg::User->encode({
      sha256_hash => Digest::SHA::sha256("whatever"),
    });

Numeric values are stored in little-endian format so if you use raw accessors on arrays with elements of more than 2 byte sizes then you will need to C<pack> and C<unpack> them in order for your code to be portable.

Also, fixed arrays are more limited than dynamic arrays in that the schema can't be evolved by converting them into arrays of nested qstructs.

Because of the portability and schema evolution restrictions, fixed arrays and raw array access are usually recommended against.


=head1 EXCEPTIONS

This module will throw exceptions in the following conditions:

    * Schema parse errors

    * Decoding or accessing truncated/malformed qstructs

    * Out of memory during encoding

    * You are on a 32-bit system and you attempt to access
      a field that can't fit in your address space

    * Trying to set an array from a raw buffer that is the
      incorrect size

    * Attempting to modify a Qstruct::Array

Note that if fields aren't set, accessing them will I<not> throw exceptions. Instead, accessors will return the default values of their respective types (see L<Qstruct::Spec>). This is so that you can still parse old messages that were created with old versions of a schema.


=head1 PORTABILITY

This module uses the "slow" but portable accessors described in L<libqstruct|https://github.com/hoytech/libqstruct> meaning it should work on any machine regardless of byte order or alignment requirements. Despite the name, these accessors are not actually slow relative to the overhead of making a perl function or method call so there is little point in optimising them for the perl module.

Because the perl module uses the slow and portable accessors, no matter what CPU you use you do not need to worry about loading messages from aligned offsets. When using the C API, if you choose to compile with the non-portable accessors you should be aware that depending on your CPU you may have reliabilty or performance issues if you load messages from non-aligned offsets. However, modern x86-64 CPUs are perfectly suited for the "fast" interface and this interface can be used without sacrificing reliability or performance even with non-aligned messages.



=head1 SEE ALSO

L<Qstruct::Spec> - The Qstruct design objectives and format specification

L<Video: Doug Hoyte introduces Qstruct to Toronto Perl Mongers|https://www.youtube.com/watch?v=cOYx8te1-m0>

L<Qstruct::Compiler> - The reference compiler implementation

L<Test::ZeroCopy> - More information on zero-copy and how it is tested for

L<libqstruct|https://github.com/hoytech/libqstruct> - Shared C library

L<Qstruct github repo|https://github.com/hoytech/Qstruct>


=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2014 Doug Hoyte.

This module is licensed under the same terms as perl itself.

The bundled C<libqstruct> is (C) Doug Hoyte and licensed under the 2-clause BSD license.

=cut



TODO:

!! make sure pointers always point forwards
!! make sure no identifiers have adjacent _s in their names
!! enums

tests:
  * nested qstructs
  * malformed messages
    * backwards pointers
    * when accessing body fields, if the body is too short it returns default values (and never reads into the heap)


TODO long-term:

!! support "out-of-order" qstruct definitions (ie without needing forward declarations)

tests:
  * bit-manipulation fuzzer (run in valgrind/-fsanitize=address)

canonicalisation, copy method
vectored I/O builder for 0-copy/1-copy building
"zero-copy" encode (ie output param for encode methods)
fewer copies in encode method after final malloc
  ?? maybe it can steal the malloc buffer and be zerocopy
?? :encoding(utf8) type modifier that enforces character encodings on encoding and decoding
?? :align(32) type modifier

Qstruct::Compiler
  * QSTRUCT_ERRNO_* / qstruct_strerror() system

doug@neptune:~/Qstruct$ perl -MQstruct -E 'Qstruct::load_schema(q{           })'
Qstruct::parse error: ����I� at /usr/local/lib/perl/5.14.2/Qstruct.pm line 297.
