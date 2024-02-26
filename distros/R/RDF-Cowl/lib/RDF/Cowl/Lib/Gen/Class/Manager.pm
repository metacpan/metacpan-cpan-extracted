package RDF::Cowl::Lib::Gen::Class::Manager;
# ABSTRACT: Private class for RDF::Cowl::Manager
$RDF::Cowl::Lib::Gen::Class::Manager::VERSION = '1.0.0';
## DO NOT EDIT
## Generated via maint/tt/Class.pm.tt

package # hide from PAUSE
  RDF::Cowl::Manager;

use strict;
use warnings;
use feature qw(state);
use Devel::StrictMode qw( STRICT );
use RDF::Cowl::Lib qw(arg);
use RDF::Cowl::Lib::Types qw(:all);
use Types::Common qw(Maybe BoolLike PositiveOrZeroInt Str StrMatch InstanceOf);
use Type::Params -sigs;

my $ffi = RDF::Cowl::Lib->ffi;


# cowl_manager
$ffi->attach( [
 "COWL_WRAP_cowl_manager"
 => "new" ] =>
	[
	],
	=> "CowlManager"
	=> sub {
		my $RETVAL;
		my $xs    = shift;
		my $class = shift;


		$RETVAL = $xs->( @_ );

		die "RDF::Cowl::Manager::new: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_manager_set_reader
$ffi->attach( [
 "COWL_WRAP_cowl_manager_set_reader"
 => "set_reader" ] =>
	[
		arg "CowlManager" => "manager",
		arg "CowlReader" => "reader",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				CowlReader, { name => "reader", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_manager_set_writer
$ffi->attach( [
 "COWL_WRAP_cowl_manager_set_writer"
 => "set_writer" ] =>
	[
		arg "CowlManager" => "manager",
		arg "CowlWriter" => "writer",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				CowlWriter, { name => "writer", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_manager_set_import_loader
$ffi->attach( [
 "COWL_WRAP_cowl_manager_set_import_loader"
 => "set_import_loader" ] =>
	[
		arg "CowlManager" => "manager",
		arg "CowlImportLoader" => "loader",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				CowlImportLoader, { name => "loader", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_manager_set_error_handler
$ffi->attach( [
 "COWL_WRAP_cowl_manager_set_error_handler"
 => "set_error_handler" ] =>
	[
		arg "CowlManager" => "manager",
		arg "CowlErrorHandler" => "handler",
	],
	=> "void"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				CowlErrorHandler, { name => "handler", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_manager_get_ontology
$ffi->attach( [
 "COWL_WRAP_cowl_manager_get_ontology"
 => "get_ontology" ] =>
	[
		arg "CowlManager" => "manager",
		arg "CowlOntologyId" => "id",
	],
	=> "CowlOntology"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				CowlOntologyId, { name => "id", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_manager_read_path
$ffi->attach( [
 "COWL_WRAP_cowl_manager_read_path"
 => "read_path" ] =>
	[
		arg "CowlManager" => "manager",
		arg "UString" => "path",
	],
	=> "CowlOntology"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				UString, { name => "path", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::Manager::read_path: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_manager_read_file
# See manual binding definition.


# cowl_manager_read_string
$ffi->attach( [
 "COWL_WRAP_cowl_manager_read_string"
 => "read_string" ] =>
	[
		arg "CowlManager" => "manager",
		arg "UString" => "string",
	],
	=> "CowlOntology"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				UString, { name => "string", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::Manager::read_string: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_manager_read_stream
$ffi->attach( [
 "COWL_WRAP_cowl_manager_read_stream"
 => "read_stream" ] =>
	[
		arg "CowlManager" => "manager",
		arg "UIStream" => "stream",
	],
	=> "CowlOntology"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				UIStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		die "RDF::Cowl::Manager::read_stream: error: returned NULL" unless defined $RETVAL;
		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 1;
		return $RETVAL;
	}
);


# cowl_manager_write_path
$ffi->attach( [
 "COWL_WRAP_cowl_manager_write_path"
 => "write_path" ] =>
	[
		arg "CowlManager" => "manager",
		arg "CowlOntology" => "ontology",
		arg "UString" => "path",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				CowlOntology, { name => "ontology", },
				UString, { name => "path", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_manager_write_file
# See manual binding definition.


# cowl_manager_write_strbuf
$ffi->attach( [
 "COWL_WRAP_cowl_manager_write_strbuf"
 => "write_strbuf" ] =>
	[
		arg "CowlManager" => "manager",
		arg "CowlOntology" => "ontology",
		arg "UStrBuf" => "buf",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				CowlOntology, { name => "ontology", },
				UStrBuf, { name => "buf", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_manager_write_stream
$ffi->attach( [
 "COWL_WRAP_cowl_manager_write_stream"
 => "write_stream" ] =>
	[
		arg "CowlManager" => "manager",
		arg "CowlOntology" => "ontology",
		arg "UOStream" => "stream",
	],
	=> "cowl_ret"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				CowlOntology, { name => "ontology", },
				UOStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		return $RETVAL;
	}
);


# cowl_manager_get_istream
$ffi->attach( [
 "COWL_WRAP_cowl_manager_get_istream"
 => "get_istream" ] =>
	[
		arg "CowlManager" => "manager",
		arg "CowlIStreamHandlers" => "handlers",
	],
	=> "CowlIStream"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				CowlIStreamHandlers, { name => "handlers", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_manager_get_istream_to_ontology
$ffi->attach( [
 "COWL_WRAP_cowl_manager_get_istream_to_ontology"
 => "get_istream_to_ontology" ] =>
	[
		arg "CowlManager" => "manager",
		arg "CowlOntology" => "ontology",
	],
	=> "CowlIStream"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				CowlOntology, { name => "ontology", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


# cowl_manager_get_ostream
$ffi->attach( [
 "COWL_WRAP_cowl_manager_get_ostream"
 => "get_ostream" ] =>
	[
		arg "CowlManager" => "manager",
		arg "UOStream" => "stream",
	],
	=> "CowlOStream"
	=> sub {
		my $RETVAL;
		my $xs    = shift;


		state $signature = signature(
			strictness => STRICT,
			pos => [
				CowlManager, { name => "manager", },
				UOStream, { name => "stream", },
			],
		);

		$RETVAL = $xs->( &$signature );

		$RDF::Cowl::Object::_INSIDE_OUT{$$RETVAL}{retained} = 0;
		$RETVAL = $RETVAL->retain;
		return $RETVAL;
	}
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RDF::Cowl::Lib::Gen::Class::Manager - Private class for RDF::Cowl::Manager

=head1 VERSION

version 1.0.0

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Auto-Parallel Technologies, Inc..

This is free software, licensed under Eclipse Public License - v 2.0.

=cut
