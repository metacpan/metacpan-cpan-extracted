#=============================================================================
#
#       Copyright (c) 2010 Ars Aperta, Itaapy, Pierlis, Talend.
#       Copyright (c) 2011 Jean-Marie Gouarné.
#       Author: Jean-Marie Gouarné <jean.marie.gouarne@online.fr>
#
#=============================================================================
use     5.010_000;
use     strict;
#=============================================================================
package ODF::lpOD::Attributes;
our $VERSION    = '1.000';
use constant PACKAGE_DATE => '2010-12-24T13:57:50';
#==============================================================================
%ODF::lpOD::Connector::ATTRIBUTE =
	(
	caption_id                      =>
		{
		attribute => "draw:caption-id",
		type      => "IDREF"
		},
	z_index                         =>
		{
		attribute => "draw:z-index",
		type      => "nonNegativeInteger"
		},
	type                            =>
		{
		attribute => "draw:type",
		type      => "Unknown"
		},
	x1                              =>
		{
		attribute => "svg:x1",
		type      => "coordinate"
		},
	y1                              =>
		{
		attribute => "svg:y1",
		type      => "coordinate"
		},
	start_shape                     =>
		{
		attribute => "draw:start-shape",
		type      => "IDREF"
		},
	start_glue_point                =>
		{
		attribute => "draw:start-glue-point",
		type      => "nonNegativeInteger"
		},
	x2                              =>
		{
		attribute => "svg:x2",
		type      => "coordinate"
		},
	y2                              =>
		{
		attribute => "svg:y2",
		type      => "coordinate"
		},
	end_shape                       =>
		{
		attribute => "draw:end-shape",
		type      => "IDREF"
		},
	end_glue_point                  =>
		{
		attribute => "draw:end-glue-point",
		type      => "nonNegativeInteger"
		},
	line_skew                       =>
		{
		attribute => "draw:line-skew",
		type      => "length"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Ellipse::ATTRIBUTE =
	(
	caption_id                      =>
		{
		attribute => "draw:caption-id",
		type      => "IDREF"
		},
	z_index                         =>
		{
		attribute => "draw:z-index",
		type      => "nonNegativeInteger"
		},
	width                           =>
		{
		attribute => "svg:width",
		type      => "length"
		},
	height                          =>
		{
		attribute => "svg:height",
		type      => "length"
		},
	x                               =>
		{
		attribute => "svg:x",
		type      => "coordinate"
		},
	y                               =>
		{
		attribute => "svg:y",
		type      => "coordinate"
		},
	rx                              =>
		{
		attribute => "svg:rx",
		type      => "length"
		},
	ry                              =>
		{
		attribute => "svg:ry",
		type      => "length"
		},
	cx                              =>
		{
		attribute => "svg:cx",
		type      => "coordinate"
		},
	cy                              =>
		{
		attribute => "svg:cy",
		type      => "coordinate"
		},
	kind                            =>
		{
		attribute => "draw:kind",
		type      => "Unknown"
		},
	start_angle                     =>
		{
		attribute => "draw:start-angle",
		type      => "double"
		},
	end_angle                       =>
		{
		attribute => "draw:end-angle",
		type      => "double"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Frame::ATTRIBUTE =
	(
	copy_of                         =>
		{
		attribute => "draw:copy-of",
		type      => "string"
		},
	class                           =>
		{
		attribute => "presentation:class",
		type      => "presentation-classes"
		},
	placeholder                     =>
		{
		attribute => "presentation:placeholder",
		type      => "boolean"
		},
	user_transformed                =>
		{
		attribute => "presentation:user-transformed",
		type      => "boolean"
		},
	caption_id                      =>
		{
		attribute => "draw:caption-id",
		type      => "IDREF"
		},
	width                           =>
		{
		attribute => "svg:width",
		type      => "length"
		},
	height                          =>
		{
		attribute => "svg:height",
		type      => "length"
		},
	x                               =>
		{
		attribute => "svg:x",
		type      => "coordinate"
		},
	y                               =>
		{
		attribute => "svg:y",
		type      => "coordinate"
		},
	z_index                         =>
		{
		attribute => "draw:z-index",
		type      => "nonNegativeInteger"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Image::ATTRIBUTE =
	(
	filter_name                     =>
		{
		attribute => "draw:filter-name",
		type      => "string"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Line::ATTRIBUTE =
	(
	caption_id                      =>
		{
		attribute => "draw:caption-id",
		type      => "IDREF"
		},
	z_index                         =>
		{
		attribute => "draw:z-index",
		type      => "nonNegativeInteger"
		},
	x1                              =>
		{
		attribute => "svg:x1",
		type      => "coordinate"
		},
	y1                              =>
		{
		attribute => "svg:y1",
		type      => "coordinate"
		},
	x2                              =>
		{
		attribute => "svg:x2",
		type      => "coordinate"
		},
	y2                              =>
		{
		attribute => "svg:y2",
		type      => "coordinate"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::DrawPage::ATTRIBUTE =
	(
	name                            =>
		{
		attribute => "draw:name",
		type      => "string"
		},
	style_name                      =>
		{
		attribute => "draw:style-name",
		type      => "styleNameRef"
		},
	master_page_name                =>
		{
		attribute => "draw:master-page-name",
		type      => "styleNameRef"
		},
	presentation_page_layout_name   =>
		{
		attribute => "presentation:presentation-page-layout-name",
		type      => "styleNameRef"
		},
	id                              =>
		{
		attribute => "draw:id",
		type      => "ID"
		},
	nav_order                       =>
		{
		attribute => "draw:nav-order",
		type      => "IDREFS"
		},
	use_header_name                 =>
		{
		attribute => "presentation:use-header-name",
		type      => "string"
		},
	use_footer_name                 =>
		{
		attribute => "presentation:use-footer-name",
		type      => "string"
		},
	use_date_time_name              =>
		{
		attribute => "presentation:use-date-time-name",
		type      => "string"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Rectangle::ATTRIBUTE =
	(
	caption_id                      =>
		{
		attribute => "draw:caption-id",
		type      => "IDREF"
		},
	z_index                         =>
		{
		attribute => "draw:z-index",
		type      => "nonNegativeInteger"
		},
	width                           =>
		{
		attribute => "svg:width",
		type      => "length"
		},
	height                          =>
		{
		attribute => "svg:height",
		type      => "length"
		},
	x                               =>
		{
		attribute => "svg:x",
		type      => "coordinate"
		},
	y                               =>
		{
		attribute => "svg:y",
		type      => "coordinate"
		},
	corner_radius                   =>
		{
		attribute => "draw:corner-radius",
		type      => "nonNegativeLength"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Annotation::ATTRIBUTE =
	(
	z_index                         =>
		{
		attribute => "draw:z-index",
		type      => "nonNegativeInteger"
		},
	width                           =>
		{
		attribute => "svg:width",
		type      => "length"
		},
	height                          =>
		{
		attribute => "svg:height",
		type      => "length"
		},
	x                               =>
		{
		attribute => "svg:x",
		type      => "coordinate"
		},
	y                               =>
		{
		attribute => "svg:y",
		type      => "coordinate"
		},
	caption_point_x                 =>
		{
		attribute => "draw:caption-point-x",
		type      => "coordinate"
		},
	caption_point_y                 =>
		{
		attribute => "draw:caption-point-y",
		type      => "coordinate"
		},
	corner_radius                   =>
		{
		attribute => "draw:corner-radius",
		type      => "nonNegativeLength"
		},
	display                         =>
		{
		attribute => "office:display",
		type      => "boolean"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::MasterPage::ATTRIBUTE =
	(
	name                            =>
		{
		attribute => "style:name",
		type      => "styleName"
		},
	display_name                    =>
		{
		attribute => "style:display-name",
		type      => "string"
		},
	page_layout_name                =>
		{
		attribute => "style:page-layout-name",
		type      => "styleNameRef"
		},
	style_name                      =>
		{
		attribute => "draw:style-name",
		type      => "styleNameRef"
		},
	next_style_name                 =>
		{
		attribute => "style:next-style-name",
		type      => "styleNameRef"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::PageLayout::ATTRIBUTE =
	(
	name                            =>
		{
		attribute => "style:name",
		type      => "styleName"
		},
	page_usage                      =>
		{
		attribute => "style:page-usage",
		type      => "Unknown"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::PresentationPageLayout::ATTRIBUTE =
	(
	name                            =>
		{
		attribute => "style:name",
		type      => "styleName"
		},
	display_name                    =>
		{
		attribute => "style:display-name",
		type      => "string"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Style::ATTRIBUTE =
	(
	name                            =>
		{
		attribute => "style:name",
		type      => "styleName"
		},
	display_name                    =>
		{
		attribute => "style:display-name",
		type      => "string"
		},
	parent_style_name               =>
		{
		attribute => "style:parent-style-name",
		type      => "styleNameRef"
		},
	next_style_name                 =>
		{
		attribute => "style:next-style-name",
		type      => "styleNameRef"
		},
	list_style_name                 =>
		{
		attribute => "style:list-style-name",
		type      => "styleName"
		},
	master_page_name                =>
		{
		attribute => "style:master-page-name",
		type      => "styleNameRef"
		},
	auto_update                     =>
		{
		attribute => "style:auto-update",
		type      => "boolean"
		},
	data_style_name                 =>
		{
		attribute => "style:data-style-name",
		type      => "styleNameRef"
		},
	class                           =>
		{
		attribute => "style:class",
		type      => "string"
		},
	default_outline_level           =>
		{
		attribute => "style:default-outline-level",
		type      => "positiveInteger"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Cell::ATTRIBUTE =
	(
	number_columns_spanned          =>
		{
		attribute => "table:number-columns-spanned",
		type      => "positiveInteger"
		},
	number_rows_spanned             =>
		{
		attribute => "table:number-rows-spanned",
		type      => "positiveInteger"
		},
	number_matrix_columns_spanned   =>
		{
		attribute => "table:number-matrix-columns-spanned",
		type      => "positiveInteger"
		},
	number_matrix_rows_spanned      =>
		{
		attribute => "table:number-matrix-rows-spanned",
		type      => "positiveInteger"
		},
	number_columns_repeated         =>
		{
		attribute => "table:number-columns-repeated",
		type      => "positiveInteger"
		},
	style_name                      =>
		{
		attribute => "table:style-name",
		type      => "styleNameRef"
		},
	content_validation_name         =>
		{
		attribute => "table:content-validation-name",
		type      => "string"
		},
	formula                         =>
		{
		attribute => "table:formula",
		type      => "string"
		},
	protect                         =>
		{
		attribute => "table:protect",
		type      => "boolean"
		}
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Table::ATTRIBUTE =
	(
	name                            =>
		{
		attribute => "table:name",
		type      => "string"
		},
	style_name                      =>
		{
		attribute => "table:style-name",
		type      => "styleNameRef"
		},
	protected                       =>
		{
		attribute => "table:protected",
		type      => "boolean"
		},
	protection_key                  =>
		{
		attribute => "table:protection-key",
		type      => "Unknown"
		},
	print                           =>
		{
		attribute => "table:print",
		type      => "boolean"
		},
	print_ranges                    =>
		{
		attribute => "table:print-ranges",
		type      => "cellRangeAddressList"
		},
	is_sub_table                    =>
		{
		attribute => "table:is-sub-table",
		type      => "boolean"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Column::ATTRIBUTE =
	(
	number_columns_repeated         =>
		{
		attribute => "table:number-columns-repeated",
		type      => "positiveInteger"
		},
	style_name                      =>
		{
		attribute => "table:style-name",
		type      => "styleNameRef"
		},
	visibility                      =>
		{
		attribute => "table:visibility",
		type      => "table-visibility-value"
		},
	default_cell_style_name         =>
		{
		attribute => "table:default-cell-style-name",
		type      => "styleNameRef"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::ColumnGroup::ATTRIBUTE =
	(
	display                         =>
		{
		attribute => "table:display",
		type      => "boolean"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Row::ATTRIBUTE =
	(
	number_rows_repeated            =>
		{
		attribute => "table:number-rows-repeated",
		type      => "positiveInteger"
		},
	style_name                      =>
		{
		attribute => "table:style-name",
		type      => "styleNameRef"
		},
	default_cell_style_name         =>
		{
		attribute => "table:default-cell-style-name",
		type      => "styleNameRef"
		},
	visibility                      =>
		{
		attribute => "table:visibility",
		type      => "table-visibility-value"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::RowGroup::ATTRIBUTE =
	(
	display                         =>
		{
		attribute => "table:display",
		type      => "boolean"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::BibliographyMark::ATTRIBUTE =
	(
	bibliography_type               =>
		{
		attribute => "text:bibliography-type",
		type      => "text-bibliography-types"
		},
	identifier                      =>
		{
		attribute => "text:identifier",
		type      => "string"
		},
	address                         =>
		{
		attribute => "text:address",
		type      => "string"
		},
	annote                          =>
		{
		attribute => "text:annote",
		type      => "string"
		},
	author                          =>
		{
		attribute => "text:author",
		type      => "string"
		},
	booktitle                       =>
		{
		attribute => "text:booktitle",
		type      => "string"
		},
	chapter                         =>
		{
		attribute => "text:chapter",
		type      => "string"
		},
	edition                         =>
		{
		attribute => "text:edition",
		type      => "string"
		},
	editor                          =>
		{
		attribute => "text:editor",
		type      => "string"
		},
	howpublished                    =>
		{
		attribute => "text:howpublished",
		type      => "string"
		},
	institution                     =>
		{
		attribute => "text:institution",
		type      => "string"
		},
	journal                         =>
		{
		attribute => "text:journal",
		type      => "string"
		},
	month                           =>
		{
		attribute => "text:month",
		type      => "string"
		},
	note                            =>
		{
		attribute => "text:note",
		type      => "string"
		},
	number                          =>
		{
		attribute => "text:number",
		type      => "string"
		},
	organizations                   =>
		{
		attribute => "text:organizations",
		type      => "string"
		},
	pages                           =>
		{
		attribute => "text:pages",
		type      => "string"
		},
	publisher                       =>
		{
		attribute => "text:publisher",
		type      => "string"
		},
	school                          =>
		{
		attribute => "text:school",
		type      => "string"
		},
	series                          =>
		{
		attribute => "text:series",
		type      => "string"
		},
	title                           =>
		{
		attribute => "text:title",
		type      => "string"
		},
	report_type                     =>
		{
		attribute => "text:report-type",
		type      => "string"
		},
	volume                          =>
		{
		attribute => "text:volume",
		type      => "string"
		},
	year                            =>
		{
		attribute => "text:year",
		type      => "string"
		},
	url                             =>
		{
		attribute => "text:url",
		type      => "string"
		},
	custom1                         =>
		{
		attribute => "text:custom1",
		type      => "string"
		},
	custom2                         =>
		{
		attribute => "text:custom2",
		type      => "string"
		},
	custom3                         =>
		{
		attribute => "text:custom3",
		type      => "string"
		},
	custom4                         =>
		{
		attribute => "text:custom4",
		type      => "string"
		},
	custom5                         =>
		{
		attribute => "text:custom5",
		type      => "string"
		},
	isbn                            =>
		{
		attribute => "text:isbn",
		type      => "string"
		},
	issn                            =>
		{
		attribute => "text:issn",
		type      => "string"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::ChangedRegion::ATTRIBUTE =
	(
	id                              =>
		{
		attribute => "text:id",
		type      => "ID"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Heading::ATTRIBUTE =
	(
	style_name                      =>
		{
		attribute => "text:style-name",
		type      => "styleNameRef"
		},
	class_names                     =>
		{
		attribute => "text:class-names",
		type      => "styleNameRefs"
		},
	cond_style_name                 =>
		{
		attribute => "text:cond-style-name",
		type      => "styleNameRef"
		},
	outline_level                   =>
		{
		attribute => "text:outline-level",
		type      => "positiveInteger"
		},
	restart_numbering               =>
		{
		attribute => "text:restart-numbering",
		type      => "boolean"
		},
	start_value                     =>
		{
		attribute => "text:start-value",
		type      => "nonNegativeInteger"
		},
	is_list_header                  =>
		{
		attribute => "text:is-list-header",
		type      => "boolean"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::List::ATTRIBUTE =
	(
	style_name                      =>
		{
		attribute => "text:style-name",
		type      => "styleNameRef"
		},
	continue_numbering              =>
		{
		attribute => "text:continue-numbering",
		type      => "boolean"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::ListStyle::ATTRIBUTE =
	(
	name                            =>
		{
		attribute => "style:name",
		type      => "styleName"
		},
	display_name                    =>
		{
		attribute => "style:display-name",
		type      => "string"
		},
	consecutive_numbering           =>
		{
		attribute => "text:consecutive-numbering",
		type      => "boolean"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Note::ATTRIBUTE =
	(
	note_class                      =>
		{
		attribute => "text:note-class",
		type      => "Unknown"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Paragraph::ATTRIBUTE =
	(
	style_name                      =>
		{
		attribute => "text:style-name",
		type      => "styleNameRef"
		},
	class_names                     =>
		{
		attribute => "text:class-names",
		type      => "styleNameRefs"
		},
	cond_style_name                 =>
		{
		attribute => "text:cond-style-name",
		type      => "styleNameRef"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::Section::ATTRIBUTE =
	(
	style_name                      =>
		{
		attribute => "text:style-name",
		type      => "styleNameRef"
		},
	name                            =>
		{
		attribute => "text:name",
		type      => "string"
		},
	protected                       =>
		{
		attribute => "text:protected",
		type      => "boolean"
		},
	protection_key                  =>
		{
		attribute => "text:protection-key",
		type      => "string"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::TextElement::ATTRIBUTE =
	(
	style_name                      =>
		{
		attribute => "text:style-name",
		type      => "styleNameRef"
		},
	class_names                     =>
		{
		attribute => "text:class-names",
		type      => "styleNameRefs"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::TOC::ATTRIBUTE =
	(
	style_name                      =>
		{
		attribute => "text:style-name",
		type      => "styleNameRef"
		},
	name                            =>
		{
		attribute => "text:name",
		type      => "string"
		},
	protected                       =>
		{
		attribute => "text:protected",
		type      => "boolean"
		},
	protection_key                  =>
		{
		attribute => "text:protection-key",
		type      => "string"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::UserVariable::ATTRIBUTE =
	(
	value_type                      =>
		{
		attribute => "office:value-type",
		type      => "Unknown"
		},
	value                           =>
		{
		attribute => "office:value",
		type      => "double"
		},
	value_type                      =>
		{
		attribute => "office:value-type",
		type      => "Unknown"
		},
	value                           =>
		{
		attribute => "office:value",
		type      => "double"
		},
	value_type                      =>
		{
		attribute => "office:value-type",
		type      => "Unknown"
		},
	value                           =>
		{
		attribute => "office:value",
		type      => "double"
		},
	currency                        =>
		{
		attribute => "office:currency",
		type      => "string"
		},
	value_type                      =>
		{
		attribute => "office:value-type",
		type      => "Unknown"
		},
	date_value                      =>
		{
		attribute => "office:date-value",
		type      => "dateOrDateTime"
		},
	value_type                      =>
		{
		attribute => "office:value-type",
		type      => "Unknown"
		},
	time_value                      =>
		{
		attribute => "office:time-value",
		type      => "duration"
		},
	value_type                      =>
		{
		attribute => "office:value-type",
		type      => "Unknown"
		},
	boolean_value                   =>
		{
		attribute => "office:boolean-value",
		type      => "boolean"
		},
	value_type                      =>
		{
		attribute => "office:value-type",
		type      => "Unknown"
		},
	string_value                    =>
		{
		attribute => "office:string-value",
		type      => "string"
		},
	name                            =>
		{
		attribute => "text:name",
		type      => "variableName"
		},
	);
#------------------------------------------------------------------------------
%ODF::lpOD::SimpleVariable::ATTRIBUTE =
	(
	value_type                      =>
		{
		attribute => "office:value-type",
		type      => "valueType"
		},
	name                            =>
		{
		attribute => "text:name",
		type      => "variableName"
		},
	);
#==============================================================================
1;
