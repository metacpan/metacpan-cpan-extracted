package Octothorpe;
use Moose;
sub xmlns {}
sub root_element {"Octothorpe"}
use PRANG::Graph;
use Moose::Util::TypeConstraints;

# class tests mixed graph structure:
#   Seq -> Quant -> Element
#   Seq -> Element
has_element "hyphen" =>
	is => "ro",
	isa => "Bool",
	xml_nodeName => "emdash",
	predicate => "has_hyphen",
	;
has_element "colon" =>
	is => "ro",
	isa => "Str",
	required => 1,
	;
has_element "apostrophe" =>
	is => "ro",
	isa => "Ampersand",
	xml_required => 0,
	;

has_element "pipe" =>
	is => "ro",
	isa => "Fingernails",
	xml_required => 0,
	;

has_element "section_mark" =>
	is => "ro",
	isa => "SectionMark",
	xml_required => 0,
	xmlns => "uri:type:A",
	;

has_element "curly_brackets" =>
	is => "ro",
	isa => "CurlyBrackets",
	xml_required => 0,
	;

has_element "question_mark" =>
	is => "ro",
	isa => "PRANG::XMLSchema::Whatever",
	xml_required => 0,
	;

has_element "number_sign" =>
	is => "ro",
	isa => "InvertedQuestionMark",
	xml_required => 0,
	;

has_element "permille_sign" =>
	is => "ro",
	isa => enum([qw(foo bar baz)]),
	xml_min => 0,
	;

with "PRANG::Graph";

package InvertedQuestionMark;
use Moose::Role;
with 'PRANG::Graph';
sub xmlns {}

package Ampersand;
use Moose;
use PRANG::Graph;

# class tests: Quant -> Element
has_element "interpunct" =>
	is => "ro",
	isa => "Int",
	predicate => "has_interpunct",
	;

sub root_element {"ampersand"}
with 'InvertedQuestionMark';

package Caret;
use Moose;
use PRANG::Graph;

# class tests:
#    Choice -> Element
#    Choice -> Element -> Text
has_element "solidus" =>
	is => "ro",
	isa => "Octothorpe|Int",
	required => 1,
	xml_nodeName => {
	"braces" => "Int",
	"parens" => "Octothorpe",
	},
	;

sub root_element {"caret"}
with 'InvertedQuestionMark';

package Asteriks;
use Moose;
use Moose::Util::TypeConstraints;
use PRANG::XMLSchema::Types;
use PRANG::Graph;

# class tests:
#    Quant -> Choice -> Element
#    Quant -> Choice -> Text

has_element "bullet" =>
	is => "ro",
	isa => "ArrayRef[Str]",
	xml_max => 5,
	required => 1,
	xml_nodeName => {
	"guillemets" => "Str",
	},
	;

package Pilcrow;
use Moose;
use PRANG::Graph;

#    Quant -> Element
has_element "backslash" =>
	is => "ro",
	isa => "ArrayRef[Asteriks]",
	xml_required => 0,
	;

package Deaeresis;
use Moose;
use PRANG::Graph;

#    Quant -> Choice with type/nodeName mapping
has_element "asterism" =>
	is => "ro",
	isa => "ArrayRef[Caret|Pilcrow|Str]",
	xml_min => 0,
	xml_nodeName => {
	"space" => "Caret",
	"underscore" => "Pilcrow",
	"slash" => "Str",
	},
	;

# test attribute name wildcarding
has_attr "currency" =>
	is => "ro",
	isa => "HashRef[Str]",
	xml_name => "*",
	;

# test attribute namespace wildcarding
has_attr "period" =>
	is => "ro",
	isa => "ArrayRef[Str]",
	xmlns => "*",
	xmlns_attr => "period_ns",
	;

has "period_ns" => is => "ro";

package Fingernails;
use Moose;
use PRANG::Graph;

#    Class tests: Seq -> Element

# test attribute xmlns wildcarding
has_attr "currency" =>
	is => "ro",
	isa => "Str",
	xml_name => "dollar_sign",
	;
has 'currency_ns' =>
	is => "ro",
	;

has_element "fishhooks" =>
	is => "ro",
	isa => "Deaeresis",
	required => 1,
	;

package SectionMark;

use Moose;
use PRANG::Graph;

# This class tests:
#     Seq -> Quant -> Choice -> Element
#      \                   `--> Element
#       \                  `--> Text
#        `-> Quant -> Choice -> Element
#                          `--> Element

# test mixed XML
has_element "double_angle_quotes" =>
	is => "ro",
	isa => "ArrayRef[Ampersand|Str|SectionMark]",
	required => 1,
	xml_nodeName => {
	"" => "Str",
	"interrobang" => "Ampersand",
	"section_mark" => "SectionMark",
	},
	;

# test the "more element names than types" case - extra attribute
# required to record the node name.
has_element "percent_sign" =>
	is => "ro",
	isa => "Ampersand",
	xml_required => 0,
	xml_nodeName => {
	"degree" => "Ampersand",
	"period" => "Ampersand",
	},
	xml_nodeName_attr => "percent_sign_type",
	;

has "percent_sign_type" =>
	is => "ro",
	;

# test the "more types than element names" case in the docs (no extra
# attributes required, but namespaces vital)
has_element "broken_bar" =>
	is => "ro",
	isa => "Ampersand|Caret",
	xml_required => 0,
	xml_nodeName => {
	"trumpery:broken_bar" => "Ampersand",
	"rubble:broken_bar" => "Caret",
	},
	xml_nodeName_prefix => {
	"trumpery" => "uri:type:A",
	"rubble" => "uri:type:B",
	},
	;

has_element "prime" =>
	is => "ro",
	isa => "Ampersand",
	xml_required => 0,
	xml_nodeName => {
	"trumpery:single_quotes" => "Ampersand",
	"rubble:single_quotes" => "Ampersand",
	},
	xml_nodeName_prefix => {
	"trumpery" => "uri:type:A",
	"rubble" => "uri:type:B",
	},
	xmlns_attr => "prime_ns",
	;

has "prime_ns" =>
	is => "ro",
	;

has_attr "suspension_points" =>
	is => "ro",
	isa => "Str",
	xmlns => "uri:type:C",
	xml_required => 0,
	;

has_attr "quotation_dash" =>
	is => "ro",
	isa => "Str",
	xmlns => "uri:type:A",
	xml_required => 0,
	xml_name => "quotation_dash",
	;

package CurlyBrackets;

use Moose;
use PRANG::Graph;

# test the "more element names than types" case - extra attribute
# required to record the node name.  This one should always go at
# the end of the class as it will happily eat all following elements
# (also should be kept in mind when trying to write invalid tests)
has_element "square_brackets" =>
	is => "ro",
	isa => "ArrayRef[Ampersand]",
	xml_required => 0,
	xml_nodeName => "*",
	xml_nodeName_attr => "square_brackets_type",
	;

has "square_brackets_type" =>
	is => "ro",
	;

1;

# Copyright (C) 2009, 2010  NZ Registry Services
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the Artistic License 2.0 or later.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# Artistic License 2.0 for more details.
#
# You should have received a copy of the Artistic License the file
# COPYING.txt.  If not, see
# <http://www.perlfoundation.org/artistic_license_2_0>
