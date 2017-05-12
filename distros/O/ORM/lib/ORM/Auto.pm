#
# DESCRIPTION
#	ORM::Auto - is module for auto create all nedded ORM classes
#	for connected to database.
#
#   PerlORM - Object relational mapper (ORM) for Perl. PerlORM is Perl
#   library that implements object-relational mapping. Its features are
#   much similar to those of Java's Hibernate library, but interface is
#   much different and easier to use.
#
# AUTHOR
#   Nickolay A. Briginetc <nick_briginetc@sourceforge.net>
#
# COPYRIGHT
#   Copyright (C) 2005-2006 Nickolay A. Briginetc & Alexey V. Akimov
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU Lesser General Public
#   License as published by the Free Software Foundation; either
#   version 2.1 of the License, or (at your option) any later version.
#
#   This library is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#   Lesser General Public License for more details.
#
#   You should have received a copy of the GNU Lesser General Public
#   License along with this library; if not, write to the Free Software
#   Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
#
#package ORMAuto;
package ORM::Auto;

use strict;

use vars qw(@ISA @EXPORT $__BASES);

@ISA = ('Exporter');

@EXPORT	= qw(orm);

$__BASES = {};

use Carp;

sub orm {
    my $config_name = shift;
	my $callpkg = scalar caller;

	# Если не указать имя конфигурации то будет использовано имя вызвавшего пакета,
	# с небольшим довеском :)
    my $base = $config_name || $callpkg.'_ORM';

	if (not exists $__BASES->{$base}) {
    	# попытка вызвать существующий модуль
    	eval "use $base;";

    	# если не получилось то создаем новый package с необходимыми свойствами.
    	my $eval = qq(package $base; use base 'ORM'; );


    	# а здесь идет внутренний eval, что возможно плохо скажется на производительности
    	# но добавляет немеряно функциональности.
    	# класс таблицы создается на лету из имени вызванной функции
    	# и если такая таблица существует то будет вполне адекватно подключена
    	# и может использоваться как объект ORM
		$eval .= q(our $__TABLES = {};);
		$eval .= q(sub AUTOLOAD { shift; use vars qw($AUTOLOAD););
		$eval .= q(return $__TABLES->{$AUTOLOAD} if exists $__TABLES->{$AUTOLOAD};);
		$eval .= q(eval "use $AUTOLOAD;";);
		$eval .= q(my $eval = "package $AUTOLOAD;";);
		$eval .= q($eval .= "use ORM::Base ').$base.q('";);
		$eval .= q($eval .= ", qw(@_)" if @_;);
		$eval .= q($eval .= "; ";);
		$eval .= q(eval $eval if $@;);
		$eval .= q(warn("$@") if $@;);
		$eval .= q(eval "do $AUTOLOAD;";);
		$eval .= q($__TABLES->{$AUTOLOAD} = $AUTOLOAD;);
		$eval .= q(return $AUTOLOAD;});

		eval $eval  if $@;
		croak("$@") if $@;

		eval "do $base";

		$__BASES->{$base} = $base;
	}

	return $base

}

sub DESTROY {
    my $self = shift;
}

=head1 NAME

    ORM::Auto - is module for auto create all nedded ORM classes
    for connected to database.

=head1 SYNOPSIS

    use ORM::Auto;
    use ORM::Error;
    use ORM::Db::DBI::SQLite;

    my $error = ORM::Error->new;

    orm->_init(
        prefer_lazy_load     => 0,
        emulate_foreign_keys => 1,
        default_cache_size   => 200,
        error	=> $error,
        db => ORM::Db::DBI::SQLite->new
            (database    => 'data/main.db')
    );
    die $error->text if $error->any;

    unless (orm->sessions(table => 't_sessions')->find_id(id => 1) {
        print "Created new session with id: ".orm->sessions->new->id;
    }

    OR for multi connected

    #Backup books
    use ORM::Auto;
    use ORM::Error;
    use ORM::Db::DBI::SQLite;
    use ORM::Db::DBI::MySQL;

    my $error = ORM::Error->new;

    # Connect to original base
	orm->_init(
        error	=> $error,
        db => ORM::Db::DBI::MySQL->new(
            host        => 'localhost',
            port        => '3306',
            database    => 'books',
            user        => 'book_man',
            password    => 'super_password'
        	)
    );
    die $error->text if $error->any;

    # create the backup base as one file
	orm('new_base')->_init(
        error	=> $error,
        db => ORM::Db::DBI::SQLite->new
            (database    => 'backup_'.time.'.db')
    );
    die $error->text if $error->any;

    # Select the books with setting interested
	my $orm_books = orm->book(table => 'book')->find(
		filter => (orm->book->M->interested == 1),
		error => $error,
		return_res => 1 );

	# Write intersted books in backup base
	while (my $orm = $orm_books->next) {
		orm('new_base')->book(table => 'books')->new(prop => {
					author     => $orm->author,
					title      => $orm->title,
					isbn       => $orm->isbn,
					published  => $orm->date_of_publish
				}
			)
		}
	}


=head1 DESCRIPTION

	This module allowed not created on disk, modules for each table in base
	Also and main module for base is not need. All created on fly :)


=item orm([config_name])

	return the primary class for connected to database
	config_name - any allowed perl identifier for different connection to bases.
	as default <caller_name> + '_ORM'.

	Example:
		package MyApp::books;
		use ORM::Auto;

		print orm; # printing MyApp::books_ORM

    However, if module config_name is exists, connected with it.

=item orm->table([parameters])

    return the table class for access to data
    parameters allowed only once, in first use. In future is not need.

=head1 SEE ALSO

L<ORM>

L<ORM::Tutorial>

L<ORM::Error>

L<ORM::ResultSet>

L<ORM::Broken>

L<ORM::Db>

L<ORM::Order>

L<ORM::Metaprop>

L<ORM::DbLog>

http://perlorm.sourceforge.net/

=head1 AUTHOR

Nickolay A. Briginetc

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Nickolay A. Briginetc & Alexey V. Akimov

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

=cut

1;