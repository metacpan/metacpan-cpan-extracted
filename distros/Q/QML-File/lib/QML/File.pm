package QML::File;
use strict;
use warnings;
use IO::File;
use base qw(Class::Accessor);

our $VERSION = 0.02;

QML::File->mk_ro_accessors(qw(name objectType id));

sub new {
    my ( $class, $file ) = @_;
    my $fileHandle = IO::File->new( $file, "r" );
    my ($name) = $file =~ /([^\.\\\/]+)\.qml$/;

    my $self = bless {
        fileHandle           => $fileHandle,
        name                 => $name,
        imports              => [],
        objectType           => '',
        id                   => {},
        propertyDeclarations => [],
        signalDeclarations   => [],
        javaScriptFunctions  => [],
        objectProperties     => [],
        childObjects         => []
    }, $class;

    $self->_parse;

    return $self;
}

sub _parse {
    my ($self) = @_;

    my $isInComment;
    my $isInFunction;
    my $isInChildObject;
    my $braceLevel = 0;
    my $lineNum    = 0;

    if ( !$self->{fileHandle} ) {
        print "ERROR: Could not open $self->{name}\n";
        return;
    }

    my @lines = $self->{fileHandle}->getlines;
    foreach my $line (@lines) {
        $lineNum++;

        # Trim leading and trailing whitespace
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        # Comment
        next if ( $line =~ /^\/\// );

        # Long Comment
        $isInComment = 1 if ( $line =~ /\/\*/ );
        if ($isInComment) {
            $isInComment = 0 if ( $line =~ /\*\// );
            next;
        }

        # FileSystemImport
        my ($filename) = $line =~ /import\s+"([^"]+)"/;
        if ( defined $filename ) {
            push @{ $self->{imports} },
              { filename => $filename, line => $line, lineNum => $lineNum };
        }

        # LibraryImport
        my ($importId) = $line =~ /import\s+([\w\d_\.]+)/;
        if ( defined $importId ) {
            push @{ $self->{imports} },
              { name => $importId, line => $line, lineNum => $lineNum };
        }

        # ObjectDeclaration
        if ( !$self->{objectType} ) {
            my ($type) = $line =~ /^([\w\d_\.]+)/;
            if ( defined $type && $type ne 'import' ) {
                $self->{objectType} =
                  { name => $type, line => $line, lineNum => $lineNum };
            }
        }

        if ( $braceLevel == 1 ) {

            # PropertyDeclaration
            my ( $propertyType, $identifier ) =
              $line =~ /^property\s+([\w\d_]+)\s+([\w\d_]+)/;
            if ( defined $propertyType ) {
                push @{ $self->{propertyDeclarations} },
                  {
                    type    => $propertyType,
                    name    => $identifier,
                    line    => $line,
                    lineNum => $lineNum
                  };
            }

            # SignalDeclaration
            my ($signalName) = $line =~ /^signal\s+([\w\d_]+)/;
            if ( defined $signalName ) {
                push @{ $self->{signalDeclarations} },
                  { name => $signalName, line => $line, lineNum => $lineNum };
            }

            # JavaScriptFunctions
            my ($functionName) = $line =~ /^function\s+([\w\d_]+)/;
            if ( defined $functionName ) {
                push @{ $self->{javaScriptFunctions} },
                  { name => $functionName, line => $line, lineNum => $lineNum };
                $isInFunction = 1;
            }

            # ObjectProperties
            my ($propertyName) = $line =~ /^([\w\d_\.]+)\s*:/;
            if ( defined $propertyName ) {
                push @{ $self->{objectProperties} },
                  { name => $propertyName, line => $line, lineNum => $lineNum };

                # ID
                if ( !defined $self->{id}->{name} ) {
                    my ($id) = $line =~ /^id\s*:\s*([\w\d_\.]+)/;
                    if ( defined $id ) {
                        $self->{id} =
                          { name => $id, line => $line, lineNum => $lineNum };
                    }
                }
            }

            # Child objects
            my ($childType) = $line =~ /^([\w\d_\.]+)\s*\{/;
            if ( defined $childType ) {
                next if $childType =~ /^anchors|font$/;
                push @{ $self->{childObjects} },
                  { type => $childType, line => $line, lineNum => $lineNum };
            }
        }

        # Curly braces
        $braceLevel += ( $line =~ tr/\{// );
        $braceLevel -= ( $line =~ tr/\}// );
    }
}

sub imports {
    my ($self) = @_;
    return @{ $self->{imports} };
}

sub propertyDeclarations {
    my ($self) = @_;
    return @{ $self->{propertyDeclarations} };
}

sub signalDeclarations {
    my ($self) = @_;
    return @{ $self->{signalDeclarations} };
}

sub javaScriptFunctions {
    my ($self) = @_;
    return @{ $self->{javaScriptFunctions} };
}

sub objectProperties {
    my ($self) = @_;
    return @{ $self->{objectProperties} };
}

sub childObjects {
    my ($self) = @_;
    return @{ $self->{childObjects} };
}

1;
__END__

=head1 NAME

QML::File - Basic parsing of the high-level structure of QML files.

=head1 SYNOPSIS

  use QML::File 

  my $parser = new QML::File('main.qml');

  my @imports = $parser->imports;
  foreach my $import (@imports) {
    print "Found import of $import->{name} on line $import->{lineNum}\n";
  }
  my $objectType = $parser->objectType;

  my $id = $parser->id
  my @properties = $parser->propertyDeclarations;
  my @signals = $parser->signalDeclarations;
  my @functions = $parser->javaScriptFunctions;
  my @objectProperties = $parser->objectProperties;
  my @childObjects = $parser->childObjects;

=head1 DESCRIPTION

This module parses QML files at a very high level, allowing you to
determine basic information like the signals, properties, functions,
and child objects defined in the QML file.

=head1 CONSTRUCTOR

=head2 new

  use QML::File;
  my $file = new QML::File('Filename.qml');

Returns a newly created C<QML::File> object for the specified QML file.

=head1 METHODS

=head2 childObjects

Returns a list of child objects. Each element in the returned array is a hash of the form:

  my $child = {type => $childType, line => $line, lineNum => $lineNum};

=head2 id

Returns the ID  of the main component.

=head2 imports

  my @imports = $parser->imports;

Returns the list of imports defined in the file. Each element in the returned array is a hash of the form:

  my $fileImport = {filename => $filename, line => $line, lineNum => $lineNum};

or

  my $namedImport = {name => $name, line => $line, lineNum => $lineNum};

depending on the type of import.

=head2 javaScriptFunctions

Returns an array of Javascript functions defined in the QML component. Each element in the returned array is a hash of the form:

  my $function = {name => $functionName, line => $line, lineNum => $lineNum};

=head2 name

Returns the name of the QML component defined by the QML file.

=head2 objectProperties

Returns an array of object properties assigned. Each element in the returned array is a hash of the form:

  my $objectProperty = {name => $name, line => $line, lineNum => $lineNum};

=head2 objectType

Returns the type of the main component defined in the QML file.

=head2 propertyDeclarations

Returns an array of property declarations. Each element in the returned array is a hash of the form:

  my $property = {name => $name, line => $line, lineNum => $lineNum};

=head2 signalDeclarations

Returns an array of signal declarations. Each element in the returned array is a hash of the form:

  my $signal = {name => $name, line => $line, lineNum => $lineNum};

=head1 SEE ALSO

C<check_qml.pl> - Checks a QML file for coding conventions described at L<http://doc.qt.digia.com/qt/qml-coding-conventions.html>

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Zachary Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
