package Quiq;

use strict;
use warnings;

our $VERSION = '1.147';

=encoding utf8

=head1 NAME

Quiq - Class library for rapid development

=head1 DESCRIPTION

Diese Klassenbibliothek enthält anwendungsunabhängige Klassen,
die ich in Perl-Projekten (nur Unix) einsetze. Sie sind nach
einheitlichen Prinzipien konzipiert. Die Bibliothek befindet
sich unter kontinuierlicher Weiterentwicklung.

=head1 CLASSES

=over 4

=item *

L<Quiq::AnsiColor> - Erzeuge Text mit/ohne ANSI Colorcodes

=item *

L<Quiq::ApplicationPaths> - Ermittele Pfade einer Unix-Applikation

=item *

L<Quiq::Array> - Operationen auf Arrays

=item *

L<Quiq::AsciiTable> - ASCII-Tabelle parsen

=item *

L<Quiq::Assert> - Zusicherungen

=item *

L<Quiq::Cascm> - Schnittstelle zu CA Harvest SCM

=item *

L<Quiq::ClassConfig> - Verwalte Information auf Klassenebene

=item *

L<Quiq::ClassLoader> - Lade Perl-Klassen automatisch

=item *

L<Quiq::Color> - Eine Farbe des RGB-Farbraums

=item *

L<Quiq::CommandLine> - Konstruiere eine Unix-Kommandozeile

=item *

L<Quiq::Concat> - Konkateniere Zeichenketten

=item *

L<Quiq::Config> - Konfigurationsdatei in "Perl Object Notation"

=item *

L<Quiq::Confluence::Client> - Confluence-Wiki Client

=item *

L<Quiq::Confluence::Markup> - Confluence-Wiki Markup

=item *

L<Quiq::Confluence::Page> - Confluence-Wiki Seite

=item *

L<Quiq::ContentProcessor> - Prozessor für Abschnitts-Dateien

=item *

L<Quiq::ContentProcessor::BaseType> - Typ

=item *

L<Quiq::ContentProcessor::File> - Basisklasse für Ausgabe-Dateien

=item *

L<Quiq::ContentProcessor::SubType> - Sub-Typ

=item *

L<Quiq::ContentProcessor::Type> - Entität

=item *

L<Quiq::Converter> - Konvertierung von Werten

=item *

L<Quiq::Css> - Generiere CSS Code

=item *

L<Quiq::Database::Api> - Lowlevel Datenbank-Schnittstelle

=item *

L<Quiq::Database::Api::Dbi::Connection> - DBI Datenbank-Verbindung

=item *

L<Quiq::Database::Api::Dbi::Cursor> - DBI Datenbank-Cursor

=item *

L<Quiq::Database::Connection> - Verbindung zu einer Relationalen Datenbank

=item *

L<Quiq::Database::Cursor> - Datenbank-Cursor

=item *

L<Quiq::Database::DataAnalysis> - Führe Datenanalyse durch

=item *

L<Quiq::Database::ResultSet> - Liste von Datensätzen (abstrakt)

=item *

L<Quiq::Database::ResultSet::Array> - Liste von Datensätzen in Array-Repräsentation

=item *

L<Quiq::Database::ResultSet::Object> - Liste von Datensätzen in Objekt-Repräsentation

=item *

L<Quiq::Database::Row> - Basisklasse Datensatz (abstrakt)

=item *

L<Quiq::Database::Row::Array> - Datensatz als Array

=item *

L<Quiq::Database::Row::Object> - Datensatz als Objekt

=item *

L<Quiq::Database::Row::Object::Join> - Datensatz eines Join

=item *

L<Quiq::Database::Row::Object::Table> - Datensatz einer Tabelle

=item *

L<Quiq::Database::Tree> - Baum von Datensätzen

=item *

L<Quiq::Debug> - Hilfe beim Debuggen von Programmen

=item *

L<Quiq::DestinationTree> - Verwalte Zielbaum eines Datei-Generators

=item *

L<Quiq::Digest> - Erzeuge Digest

=item *

L<Quiq::DirHandle> - Verzeichnis-Handle

=item *

L<Quiq::Duration> - Rechnen und Konvertieren von Zeiträumen

=item *

L<Quiq::Epoch> - Ein Zeitpunkt

=item *

L<Quiq::ExampleCode> - Führe Beispielcode aus

=item *

L<Quiq::Excel::Writer> - Erzeuge Datei im Excel 2007+ XLSX Format

=item *

L<Quiq::FFmpeg> - Konstruiere eine FFmpeg-Kommandozeile

=item *

L<Quiq::File::Audio> - Informationen über Audio-Datei

=item *

L<Quiq::File::Image> - Informationen über Bild-Datei

=item *

L<Quiq::File::Video> - Informationen über Video-Datei

=item *

L<Quiq::FileHandle> - Datei-Handle

=item *

L<Quiq::Formatter> - Formatierung von Werten

=item *

L<Quiq::Gnuplot::Arrow> - Gnuplot-Arrow

=item *

L<Quiq::Gnuplot::Graph> - Gnuplot-Graph

=item *

L<Quiq::Gnuplot::Label> - Gnuplot-Label

=item *

L<Quiq::Gnuplot::Plot> - Gnuplot-Plot

=item *

L<Quiq::Gnuplot::Process> - Gnuplot-Prozess

=item *

L<Quiq::Hash> - Zugriffssicherer Hash mit automatisch generierten Attributmethoden

=item *

L<Quiq::Html::Base> - Basisklasse für HTML-Komponenten

=item *

L<Quiq::Html::Form::Layout> - HTML-Formular mit freiem Layout

=item *

L<Quiq::Html::Fragment> - Fragment aus HTML-, CSS- und JavaScript-Code

=item *

L<Quiq::Html::Image> - Image-Block in HTML

=item *

L<Quiq::Html::List> - HTML-Aufzählungsliste

=item *

L<Quiq::Html::Listing> - Programm-Listing in HTML

=item *

L<Quiq::Html::Page> - HTML-Seite

=item *

L<Quiq::Html::Pygments> - Syntax Highlighting in HTML

=item *

L<Quiq::Html::Table::Base> - Basisklasse für tabellengenerierende Klassen

=item *

L<Quiq::Html::Table::List> - HTML-Tabelle zum Anzeigen einer Liste von Elementen

=item *

L<Quiq::Html::Table::Simple> - HTML-Tabelle

=item *

L<Quiq::Html::Tag> - Generierung von HTML-Tags

=item *

L<Quiq::Html::Util> - Hilfsmethoden für die HTML-Generierung

=item *

L<Quiq::Html::Verbatim> - Verbatim-Block in HTML

=item *

L<Quiq::Html::Widget> - Basisklasse für HTML-Widgets

=item *

L<Quiq::Html::Widget::Button> - Schaltfläche

=item *

L<Quiq::Html::Widget::CheckBox> - Checkbox

=item *

L<Quiq::Html::Widget::CheckBoxBar> - Zeile von CheckBoxes

=item *

L<Quiq::Html::Widget::FileUpload> - Datei Upload Feld

=item *

L<Quiq::Html::Widget::Hidden> - Nicht sichtbares und nicht änderbares Formularelement

=item *

L<Quiq::Html::Widget::RadioButton> - Radio Button

=item *

L<Quiq::Html::Widget::RadioButtonBar> - Zeile von Radio Buttons

=item *

L<Quiq::Html::Widget::ReadOnly> - Nicht-änderbarer Text

=item *

L<Quiq::Html::Widget::SelectMenu> - Liste mit Einzelauswahl

=item *

L<Quiq::Html::Widget::SelectMenuColor> - Selectmenü mit farbigen Einträgen

=item *

L<Quiq::Html::Widget::TextArea> - Mehrzeiliges Textfeld

=item *

L<Quiq::Html::Widget::TextField> - Einzeiliges Textfeld

=item *

L<Quiq::Http::Client> - HTTP-Client

=item *

L<Quiq::Http::Client::Lwp> - HTTP Operationen

=item *

L<Quiq::Http::Cookie> - HTTP-Cookie

=item *

L<Quiq::Http::Message> - HTTP-Nachricht

=item *

L<Quiq::Image> - Operationen im Zusammenhang mit Bildern/Bilddateien

=item *

L<Quiq::ImageMagick> - Konstruiere eine ImageMagick-Kommandozeile

=item *

L<Quiq::ImagePool> - Speicher für Bild-Dateien

=item *

L<Quiq::ImagePool::Directory> - Unterverzeichnis eines Image-Pool

=item *

L<Quiq::ImagePool::Sequence> - Bild-Sequenz und -Ranges

=item *

L<Quiq::Ipc> - Interprozesskommunikation

=item *

L<Quiq::JQuery::Accordion> - Erzeuge HTML einer jQuery UI Accodion Reiterleiste

=item *

L<Quiq::JQuery::DataTable> - Erzeuge eine HTML/JavaScript DataTables-Tabelle

=item *

L<Quiq::JQuery::Form::ViewEdit> - Formular zum Ansehen und Bearbeiten von persistenten Daten

=item *

L<Quiq::JQuery::Function> - Nützliche Funktionen für jQuery

=item *

L<Quiq::JQuery::Tabs> - Erzeuge HTML einer jQuery UI Tabs Reiterleiste

=item *

L<Quiq::JavaScript> - Generierung von JavaScript-Code

=item *

L<Quiq::LaTeX::Code> - Generator für LaTeX Code

=item *

L<Quiq::LaTeX::Document> - Erzeuge LaTeX Dokument

=item *

L<Quiq::LaTeX::Figure> - Erzeuge LaTeX Figure

=item *

L<Quiq::LaTeX::LongTable> - Erzeuge LaTeX longtable

=item *

L<Quiq::LineProcessor> - Verarbeite Datei als Array von Zeilen

=item *

L<Quiq::LineProcessor::Line> - Zeile einer Datei

=item *

L<Quiq::LockedCounter> - Persistenter Zähler mit Lock

=item *

L<Quiq::Math> - Mathematische Funktionen

=item *

L<Quiq::MediaWiki::Client> - Clientseitiger Zugriff auf ein MediaWiki

=item *

L<Quiq::MediaWiki::Markup> - MediaWiki Code Generator

=item *

L<Quiq::ModelCache> - Verwaltung/Caching von Modell-Objekten

=item *

L<Quiq::Mojolicious::Plugin::Log::Parameters> - Logge Request-Parameter

=item *

L<Quiq::Object> - Basisklasse für alle Klassen der Klassenbibliothek

=item *

L<Quiq::Option> - Verarbeitung von Programm- und Methoden-Optionen

=item *

L<Quiq::OrderedHash> - Hash mit geordneten Elementen

=item *

L<Quiq::Parallel> - Parallele Verarbeitung

=item *

L<Quiq::Parameters> - Verarbeitung von Programm- und Methodenparametern

=item *

L<Quiq::Path> - Dateisystem-Operationen

=item *

L<Quiq::Perl> - Erweiterte und abgesicherte Perl-Operationen

=item *

L<Quiq::PersistentHash> - Persistenter Hash

=item *

L<Quiq::Pod::Generator> - POD-Generator

=item *

L<Quiq::Process> - Information über den laufenden Prozess

=item *

L<Quiq::Program> - Basisklasse für Programme

=item *

L<Quiq::Progress> - Berechne Fortschrittsinformation

=item *

L<Quiq::Properties> - Eigenschaften einer Menge von skalaren Werten

=item *

L<Quiq::Record> - Verarbeitung von Text-Records

=item *

L<Quiq::Reference> - Operationen auf Referenzen

=item *

L<Quiq::Rsync> - Aufruf von rsync von Perl aus

=item *

L<Quiq::Section::Object> - Abschnitts-Objekt

=item *

L<Quiq::Section::Parser> - Parser für Abschnitte

=item *

L<Quiq::Shell> - Ausführung von Shell-Kommandos

=item *

L<Quiq::SoapWsdlServiceCgi> - Basisklasse für SOAP Web Services via CGI

=item *

L<Quiq::SoapWsdlServiceCgi::Demo> - Demo für SOAP Web Service

=item *

L<Quiq::Socket> - TCP-Verbindung zu einem Server

=item *

L<Quiq::Sql> - Klasse zur Generierung von SQL

=item *

L<Quiq::SqlPlus> - Erzeuge Code für SQL*Plus

=item *

L<Quiq::Ssh> - Führe Kommando per SSH aus

=item *

L<Quiq::Stacktrace> - Generiere und visualisiere einen Stacktrace

=item *

L<Quiq::Stopwatch> - Zeitmesser

=item *

L<Quiq::Storable> - Persistenz für Perl-Datenstrukturen

=item *

L<Quiq::String> - Operationen auf Zeichenketten

=item *

L<Quiq::System> - Information über das System und seine Umgebung

=item *

L<Quiq::Table> - Tabelle

=item *

L<Quiq::TableRow> - Tabellenzeile

=item *

L<Quiq::TeX::Code> - Generator für TeX Code

=item *

L<Quiq::TempDir> - Temporäres Verzeichnis

=item *

L<Quiq::TempFile> - Temporäre Datei

=item *

L<Quiq::Template> - Klasse für HTML/XML/Text-Generierung

=item *

L<Quiq::Terminal> - Ein- und Ausgabe aufs Terminal

=item *

L<Quiq::Test::Class> - Basisklasse für Testklassen

=item *

L<Quiq::Test::Class::Method> - Testmethode

=item *

L<Quiq::Time> - Klasse zur Repräsentation von Datum und Uhrzeit

=item *

L<Quiq::Time::RFC822> - Erzeuge Zeitangabe nach RFC 822

=item *

L<Quiq::TimeLapse::Directory> - Bildsequenz-Verzeichnis

=item *

L<Quiq::TimeLapse::File> - Bildsequenz-Datei

=item *

L<Quiq::TimeLapse::Filename> - Bildsequenz-Dateiname

=item *

L<Quiq::TimeLapse::RangeDef> - Range-Definitionen

=item *

L<Quiq::TimeLapse::Sequence> - Bildsequenz

=item *

L<Quiq::Timeseries::Synchronizer> - Rasterung/Synchronisation von Zeitreihen

=item *

L<Quiq::TreeFormatter> - Erzeugung von Baumdarstellungen

=item *

L<Quiq::Udl> - Universal Database Locator

=item *

L<Quiq::Unindent> - Entferne Einrückung von "Here Document" oder String-Literal

=item *

L<Quiq::Url> - URL Klasse

=item *

L<Quiq::XTerm> - XTerminal Fenster

=item *

L<Quiq::Xml::LibXml> - Funktionale Erweiterungen von XML::LibXML

=back

=head1 INSTALLATION

    $ cpanm Quiq

=head1 VERSION

1.147

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

# eof
