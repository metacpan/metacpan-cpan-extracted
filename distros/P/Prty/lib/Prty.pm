package Prty;

use strict;
use warnings;

our $VERSION = 1.121;

=encoding utf8

=head1 NAME

Prty - Class library

=head1 DESCRIPTION

Diese Klassenbibliothek enthält anwendungsunabhängige Klassen,
die ich in Perl-Projekten einsetze. Sie sind nach
einheitlichen Prinzipien konzipiert. Die Bibliothek befindet
sich unter kontinuierlicher Weiterentwicklung.

=head1 CLASSES

=over 4

=item *

L<Prty::AnsiColor> - Erzeuge Text mit ANSI Colorcodes

=item *

L<Prty::ApplicationPaths> - Ermittele Pfade einer Unix-Applikation

=item *

L<Prty::Array> - Operationen auf Arrays

=item *

L<Prty::ClassConfig> - Verwalte Information auf Klassenebene

=item *

L<Prty::ClassLoader> - Lade Perl-Klassen automatisch

=item *

L<Prty::Color> - Eine Farbe des RGB-Farbraums

=item *

L<Prty::ColumnFormat> - Format einer Text-Kolumne

=item *

L<Prty::CommandLine> - Konstruiere eine Unix-Kommandozeile

=item *

L<Prty::Config> - Konfigurationsdatei in "Perl Object Notation"

=item *

L<Prty::Confluence::Client> - Confluence-Wiki Client

=item *

L<Prty::Confluence::Markup> - Confluence-Wiki Markup

=item *

L<Prty::Confluence::Page> - Confluence-Wiki Seite

=item *

L<Prty::ContentProcessor> - Prozessor für Abschnitts-Dateien

=item *

L<Prty::ContentProcessor::BaseType> - Typ

=item *

L<Prty::ContentProcessor::File> - Basisklasse für Ausgabe-Dateien

=item *

L<Prty::ContentProcessor::SubType> - Sub-Typ

=item *

L<Prty::ContentProcessor::Type> - Entität

=item *

L<Prty::Converter> - Konvertierung von Werten

=item *

L<Prty::Css> - Generierung von CSS Code

=item *

L<Prty::Database::Api> - Lowlevel Datenbank-Schnittstelle

=item *

L<Prty::Database::Api::Dbi::Connection> - DBI Datenbank-Verbindung

=item *

L<Prty::Database::Api::Dbi::Cursor> - DBI Datenbank-Cursor

=item *

L<Prty::Database::Connection> - Verbindung zu einer Relationalen Datenbank

=item *

L<Prty::Database::Cursor> - Datenbank-Cursor

=item *

L<Prty::Database::ResultSet> - Liste von Datensätzen (abstrakt)

=item *

L<Prty::Database::ResultSet::Array> - Liste von Datensätzen in Array-Repräsentation

=item *

L<Prty::Database::ResultSet::Object> - Liste von Datensätzen in Objekt-Repräsentation

=item *

L<Prty::Database::Row> - Basisklasse Datensatz (abstrakt)

=item *

L<Prty::Database::Row::Array> - Datensatz als Array

=item *

L<Prty::Database::Row::Object> - Datensatz als Objekt

=item *

L<Prty::Database::Row::Object::Join> - Datensatz eines Join

=item *

L<Prty::Database::Row::Object::Table> - Datensatz einer Tabelle

=item *

L<Prty::Database::Tree> - Baum von Datensätzen

=item *

L<Prty::Debug> - Hilfe beim Debuggen von Programmen

=item *

L<Prty::DestinationTree> - Verwalte Zielbaum eines Datei-Generators

=item *

L<Prty::DirHandle> - Verzeichnis-Handle

=item *

L<Prty::Duration> - Rechnen und Konvertieren von Zeiträumen

=item *

L<Prty::Epoch> - Ein Zeitpunkt

=item *

L<Prty::ExampleCode> - Führe Beispielcode aus

=item *

L<Prty::FFmpeg> - Konstruiere eine FFmpeg-Kommandozeile

=item *

L<Prty::Fibu::Bankbuchung> - Buchung von einem Postbank-Konto

=item *

L<Prty::Fibu::BankbuchungListe> - Liste von Buchungen von einem Postbank-Konto

=item *

L<Prty::Fibu::Buchung> - Fibu-Buchung

=item *

L<Prty::Fibu::BuchungListe> - Liste von Fibu-Buchungen

=item *

L<Prty::File::Audio> - Informationen über Audio-Datei

=item *

L<Prty::File::Image> - Informationen über Bild-Datei

=item *

L<Prty::File::Video> - Informationen über Video-Datei

=item *

L<Prty::FileHandle> - Datei-Handle

=item *

L<Prty::Formatter> - Formatierung von Werten

=item *

L<Prty::Hash> - Zugriffssicherer Hash mit automatisch generierten Attributmethoden

=item *

L<Prty::Html::Base> - Basisklasse für HTML-Komponenten

=item *

L<Prty::Html::Form::Layout> - HTML-Formular mit freiem Layout

=item *

L<Prty::Html::Fragment> - Fragment aus HTML-, CSS- und JavaScript-Code

=item *

L<Prty::Html::List> - HTML-Aufzählungsliste

=item *

L<Prty::Html::Listing> - Programm-Listing in HTML

=item *

L<Prty::Html::Page> - HTML-Seite

=item *

L<Prty::Html::Table::Base> - Basisklasse für tabellengenerierende Klassen

=item *

L<Prty::Html::Table::List> - HTML-Tabelle zum Anzeigen einer Liste von Elementen

=item *

L<Prty::Html::Table::Simple> - HTML-Tabelle

=item *

L<Prty::Html::Tag> - Generierung von HTML-Tags

=item *

L<Prty::Html::Util> - Hilfsmethoden für die HTML-Generierung

=item *

L<Prty::Html::Widget> - Basisklasse für HTML-Widgets

=item *

L<Prty::Html::Widget::Button> - Schaltfläche

=item *

L<Prty::Html::Widget::CheckBox> - Checkbox

=item *

L<Prty::Html::Widget::CheckBoxBar> - Zeile von CheckBoxes

=item *

L<Prty::Html::Widget::FileUpload> - Datei Upload Feld

=item *

L<Prty::Html::Widget::Hidden> - Nicht sichtbares und nicht änderbares Formularelement

=item *

L<Prty::Html::Widget::RadioButton> - Radio Button

=item *

L<Prty::Html::Widget::RadioButtonBar> - Zeile von Radio Buttons

=item *

L<Prty::Html::Widget::ReadOnly> - Nicht-änderbarer Text

=item *

L<Prty::Html::Widget::SelectMenu> - Liste mit Einzelauswahl

=item *

L<Prty::Html::Widget::SelectMenuColor> - Selectmenü mit farbigen Einträgen

=item *

L<Prty::Html::Widget::TextArea> - Mehrzeiliges Textfeld

=item *

L<Prty::Html::Widget::TextField> - Einzeiliges Textfeld

=item *

L<Prty::Http::Client> - HTTP-Client

=item *

L<Prty::Http::Client::Lwp> - HTTP Operationen

=item *

L<Prty::Http::Cookie> - HTTP-Cookie

=item *

L<Prty::Http::Message> - HTTP-Nachricht

=item *

L<Prty::Image> - Operationen im Zusammenhang mit Bildern/Bilddateien

=item *

L<Prty::ImageMagick> - Konstruiere eine ImageMagick-Kommandozeile

=item *

L<Prty::ImagePool> - Speicher für Bild-Dateien

=item *

L<Prty::ImagePool::Directory> - Unterverzeichnis eines Image-Pool

=item *

L<Prty::ImagePool::Sequence> - Bild-Sequenz und -Ranges

=item *

L<Prty::Ipc> - Interprozesskommunikation

=item *

L<Prty::JQuery::Accordion> - Erzeuge HTML einer jQuery UI Accodion Reiterleiste

=item *

L<Prty::JQuery::DataTable> - Erzeuge eine HTML/JavaScript DataTables-Tabelle

=item *

L<Prty::JQuery::Form::ViewEdit> - Formular zum Ansehen und Bearbeiten von persistenten Daten

=item *

L<Prty::JQuery::Function> - Nützliche Funktionen für jQuery

=item *

L<Prty::JQuery::Tabs> - Erzeuge HTML einer jQuery UI Tabs Reiterleiste

=item *

L<Prty::JavaScript> - Generierung von JavaScript-Code

=item *

L<Prty::LockedCounter> - Persistenter Zähler mit Lock

=item *

L<Prty::Math> - Mathematische Funktionen

=item *

L<Prty::ModelCache> - Verwaltung/Caching von Modell-Objekten

=item *

L<Prty::Mojolicious::Plugin::Log::Parameters> - Logge Request-Parameter

=item *

L<Prty::Object> - Basisklasse für alle Klassen der Klassenbibliothek

=item *

L<Prty::Option> - Verarbeitung von Programm- und Methoden-Optionen

=item *

L<Prty::OrderedHash> - Hash mit geordneten Elementen

=item *

L<Prty::Parallel> - Parallele Verarbeitung

=item *

L<Prty::Path> - Dateisystem-Operationen

=item *

L<Prty::Perl> - Erweiterte und abgesicherte Perl-Operationen

=item *

L<Prty::PersistentHash> - Persistenter Hash

=item *

L<Prty::Pod::Generator> - POD-Generator

=item *

L<Prty::Process> - Information über den laufenden Prozess

=item *

L<Prty::Program> - Basisklasse für Programme

=item *

L<Prty::Progress> - Berechne Fortschrittsinformation

=item *

L<Prty::Record> - Verarbeitung von Text-Records

=item *

L<Prty::Rsync> - Aufruf von rsync von Perl aus

=item *

L<Prty::Sdoc> - Sdoc-Generator

=item *

L<Prty::Sdoc::Box> - Kasten

=item *

L<Prty::Sdoc::BridgeHead> - Zwischenüberschrift

=item *

L<Prty::Sdoc::Code> - Code-Abschnitt

=item *

L<Prty::Sdoc::Document> - Sdoc-Dokument

=item *

L<Prty::Sdoc::Figure> - Bild

=item *

L<Prty::Sdoc::Include> - Einbinden von externen Inhalten

=item *

L<Prty::Sdoc::Item> - Listenelement

=item *

L<Prty::Sdoc::KeyValRow> - Zeile einer Schlüssel/Wert-Tabelle

=item *

L<Prty::Sdoc::KeyValTable> - Schlüssel/Wert-Tabelle

=item *

L<Prty::Sdoc::Line> - Zeile einer Sdoc-Quelldatei

=item *

L<Prty::Sdoc::List> - Liste

=item *

L<Prty::Sdoc::Node> - Basisklasse für die Knoten eines Sdoc-Dokuments (abstrakt)

=item *

L<Prty::Sdoc::PageBreak> - Seitenumbruch

=item *

L<Prty::Sdoc::Paragraph> - Paragraph

=item *

L<Prty::Sdoc::Quote> - Zitat-Abschnitt

=item *

L<Prty::Sdoc::Row> - Zeile einer Tabelle

=item *

L<Prty::Sdoc::Section> - Abschnittsüberschrift

=item *

L<Prty::Sdoc::Table> - Tabelle

=item *

L<Prty::Sdoc::TableOfContents> - Inhaltsverzeichnis

=item *

L<Prty::Section::Object> - Abschnitts-Objekt

=item *

L<Prty::Section::Parser> - Parser für Abschnitte

=item *

L<Prty::Shell> - Ausführung von Shell-Kommandos

=item *

L<Prty::SoapWsdlServiceCgi> - Basisklasse für SOAP Web Services via CGI

=item *

L<Prty::SoapWsdlServiceCgi::Demo> - Demo für SOAP Web Service

=item *

L<Prty::Socket> - TCP-Verbindung zu einem Server

=item *

L<Prty::Sql> - Klasse zur Generierung von SQL

=item *

L<Prty::SqlPlus> - Erzeuge Code für SQL*Plus

=item *

L<Prty::Stacktrace> - Generiere und visualisiere einen Stacktrace

=item *

L<Prty::Storable> - Persistenz für Perl-Datenstrukturen

=item *

L<Prty::String> - Operationen auf Zeichenketten

=item *

L<Prty::System> - Information über das System und seine Umgebung

=item *

L<Prty::Template> - Klasse für HTML/XML/Text-Generierung

=item *

L<Prty::Terminal> - Ein- und Ausgabe aufs Terminal

=item *

L<Prty::Test::Class> - Basisklasse für Testklassen

=item *

L<Prty::Test::Class::Method> - Testmethode

=item *

L<Prty::TextFile> - Textdatei als Array von Zeilen

=item *

L<Prty::TextFile::Line> - Zeile einer Textdatei

=item *

L<Prty::Time> - Klasse zur Repräsentation von Datum und Uhrzeit

=item *

L<Prty::Time::RFC822> - Erzeuge Zeitangabe nach RFC 822

=item *

L<Prty::TimeLapse::Directory> - Bildsequenz-Verzeichnis

=item *

L<Prty::TimeLapse::File> - Bildsequenz-Datei

=item *

L<Prty::TimeLapse::Filename> - Bildsequenz-Dateiname

=item *

L<Prty::TimeLapse::RangeDef> - Range-Definitionen

=item *

L<Prty::TimeLapse::Sequence> - Bildsequenz

=item *

L<Prty::Timeseries::Synchronizer> - Rasterung/Synchronisation von Zeitreihen

=item *

L<Prty::TreeFormatter> - Erzeugung von Baumdarstellungen

=item *

L<Prty::Udl> - Universal Database Locator

=item *

L<Prty::Unindent> - Entferne Einrückung von "Here Document" oder String-Literal

=item *

L<Prty::Url> - URL Klasse

=item *

L<Prty::XTerm> - XTerminal Fenster

=item *

L<Prty::Xml::LibXml> - Funktionale Erweiterungen von XML::LibXML

=back

=head1 INSTALLATION

    $ cpanm Prty

=head1 VERSION

1.121

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2017 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

# eof
