# Read file Report/Porf/examples/demo.pl -------------------------------------- 
#     skip create_persons_as_array
#     skip create_persons_as_hash
#     skip create_persons_as_object
# Read file Report/Porf/examples/example_array.pl -------------------------------------- 
# Read file Report/Porf/examples/example_hash.pl -------------------------------------- 
# Read file Report/Porf/examples/example_object.pl -------------------------------------- 
# Read file Report/Porf/examples/minimal.pl -------------------------------------- 
#     skip get_data
# Read file Report/Porf/examples/minimal_array.pl -------------------------------------- 
# Read file Report/Porf/examples/minimal_hash.pl -------------------------------------- 
# Read file Report/Porf/examples/minimal_object.pl -------------------------------------- 
# Read file Report/Porf/examples/Person.pm -------------------------------------- 
#     skip new
# Read file Report/Porf/examples/presentation_mini.pl -------------------------------------- 
# Read file Report/Porf/examples/short_array.pl -------------------------------------- 
# Read file Report/Porf/examples/short_hash.pl -------------------------------------- 
# Read file Report/Porf/examples/short_object.pl -------------------------------------- 
# Read file Report/Porf/Framework.pm -------------------------------------- 
#     skip _new
#     skip extract_format_of_filename
#     skip report_configuration_as_string
#     skip auto_report
# Read file Report/Porf/Table/Simple/AutoColumnConfigurator.pm -------------------------------------- 
#     skip new
#     skip report_configuration_as_string
#     skip create_report_configuration
#     skip create_hash_report_configuration
#     skip create_array_report_configuration
# Read file Report/Porf/Table/Simple/CsvReportConfigurator.pm -------------------------------------- 
#     skip new
#     skip _init
# Read file Report/Porf/Table/Simple/HtmlReportConfigurator.pm -------------------------------------- 
#     skip new
#     skip _init
#     skip set_escape_special_chars_action
#     skip get_escape_special_chars_action
# Read file Report/Porf/Table/Simple/TextReportConfigurator.pm -------------------------------------- 
#     skip new
# Read file Report/Porf/Table/Simple.pm -------------------------------------- 
#     skip new
#     skip _init
# Read file Report/Porf/Util.pm -------------------------------------- 
#     skip escape_html_special_chars
# Read file Report/Porf.pm -------------------------------------- 
#     skip auto_report
#     skip create_report
sub get_converter { return (
     AddBackgroundColorAttribute
 => 'add_background_color_attribute',

     AddCellOutputAction
 => 'add_cell_output_action',

     AddOptionalAttribute
 => 'add_optional_attribute',

     CC
 => 'cc',

     ConfCol
 => 'conf_col',

     ConfigureColumn
 => 'configure_column',

     ConfigureComplete
 => 'configure_complete',

     ConfigureIsComplete
 => 'configure_is_complete',

     ConfigureReport
 => 'configure_report',

     ConstLengthCenter
 => 'const_length_center',

     ConstLengthLeft
 => 'const_length_left',

     ConstLengthRight
 => 'const_length_right',

     Create
 => 'create',

     CreateAction
 => 'create_action',

     CreateAndConfigureReport
 => 'create_and_configure_report',

     CreateAutoReportConfiguration
 => 'create_auto_report_configuration',

     CreateDataList
 => 'create_data_list',

     CreateReport
 => 'create_report',

     CreateReportConfigurator
 => 'create_report_configurator',

     Get
 => 'get',

     GetAge
 => 'get_age',

     GetAlternateRowColors
 => 'get_alternate_row_colors',

     GetAutoConfiguratorAction
 => 'get_auto_configurator_action',

     GetBold
 => 'get_bold',

     GetBoldHeaderLine
 => 'get_bold_header_line',

     GetCellEnd
 => 'get_cell_end',

     GetCellOutputAction
 => 'get_cell_output_action',

     GetCellOutputActions
 => 'get_cell_output_actions',

     GetCellStart
 => 'get_cell_start',

     GetCenter
 => 'get_center',

     GetColumnWidthsRef
 => 'get_column_widths_ref',

     GetConfiguratorAction
 => 'get_configurator_action',

     GetConfigureColumnAction
 => 'get_configure_column_action',

     GetConfigureCompleteAction
 => 'get_configure_complete_action',

     GetCount
 => 'get_count',

     GetDataSeparatorChar
 => 'get_data_separator_char',

     GetDataStringChar
 => 'get_data_string_char',

     GetDefaultAlign
 => 'get_default_align',

     GetDefaultColumnWidth
 => 'get_default_column_width',

     GetDefaultFormat
 => 'get_default_format',

     GetDescription
 => 'get_description',

     GetEndTableOutputAction
 => 'get_end_table_output_action',

     GetFileEnd
 => 'get_file_end',

     GetFileStart
 => 'get_file_start',

     GetFormat
 => 'get_format',

     GetHeaderEnd
 => 'get_header_end',

     GetHeaderLine
 => 'get_header_line',

     GetHeaderOutput
 => 'get_header_output',

     GetHeaderOutputAction
 => 'get_header_output_action',

     GetHeaderRowEnd
 => 'get_header_row_end',

     GetHeaderRowStart
 => 'get_header_row_start',

     GetHeaderStart
 => 'get_header_start',

     GetHeaderTextsRef
 => 'get_header_texts_ref',

     GetHorizontalSeparationBoldChar
 => 'get_horizontal_separation_bold_char',

     GetHorizontalSeparationChar
 => 'get_horizontal_separation_char',

     GetHorizontalSeparationColumnSeparator
 => 'get_horizontal_separation_column_separator',

     GetHorizontalSeparationEnd
 => 'get_horizontal_separation_end',

     GetHorizontalSeparationStart
 => 'get_horizontal_separation_start',

     GetItalics
 => 'get_italics',

     GetLeft
 => 'get_left',

     GetMaxColWidth
 => 'get_max_col_width',

     GetMaxColumnIdx
 => 'get_max_column_idx',

     GetMaxRows
 => 'get_max_rows',

     GetName
 => 'get_name',

     GetOptionValue
 => 'get_option_value',

     GetOutputEnd
 => 'get_output_end',

     GetOutputStart
 => 'get_output_start',

     GetPageEnd
 => 'get_page_end',

     GetPageStart
 => 'get_page_start',

     GetPersonRowIndexInfo
 => 'get_person_row_index_info',

     GetPrename
 => 'get_prename',

     GetRight
 => 'get_right',

     GetRowEnd
 => 'get_row_end',

     GetRowGroupChangesAction
 => 'get_row_group_changes_action',

     GetRowOutput
 => 'get_row_output',

     GetRowOutputAction
 => 'get_row_output_action',

     GetRowStart
 => 'get_row_start',

     GetSeparatorLine
 => 'get_separator_line',

     GetStartTableOutputAction
 => 'get_start_table_output_action',

     GetSurname
 => 'get_surname',

     GetTableEnd
 => 'get_table_end',

     GetTableStart
 => 'get_table_start',

     GetTableTopText
 => 'get_table_top_text',

     GetTime
 => 'get_time',

     GetVerbose
 => 'get_verbose',

     HiresActualTime
 => 'hires_actual_time',

     HiresDiffTime
 => 'hires_diff_time',

     InspectCount
 => 'inspect_count',

     InterpreteAlignment
 => 'interprete_alignment',

     InterpreteFileParameter
 => 'interprete_file_parameter',

     InterpreteValueOptions
 => 'interprete_value_options',

     IsFormat
 => 'is_format',

     PrintHashRef
 => 'print_hash_ref',

     RunExample
 => 'run_example',

     SetAge
 => 'set_age',

     SetAlternateRowColors
 => 'set_alternate_row_colors',

     SetAutoConfiguratorAction
 => 'set_auto_configurator_action',

     SetBold
 => 'set_bold',

     SetBoldHeaderLine
 => 'set_bold_header_line',

     SetCellEnd
 => 'set_cell_end',

     SetCellOutputAction
 => 'set_cell_output_action',

     SetCellStart
 => 'set_cell_start',

     SetCenter
 => 'set_center',

     SetColumnWidthsRef
 => 'set_column_widths_ref',

     SetConfiguratorAction
 => 'set_configurator_action',

     SetConfigureColumnAction
 => 'set_configure_column_action',

     SetConfigureCompleteAction
 => 'set_configure_complete_action',

     SetCount
 => 'set_count',

     SetDataSeparatorChar
 => 'set_data_separator_char',

     SetDataStringChar
 => 'set_data_string_char',

     SetDefaultAlign
 => 'set_default_align',

     SetDefaultColumnWidth
 => 'set_default_column_width',

     SetDefaultFormat
 => 'set_default_format',

     SetDefaultFramework
 => 'set_default_framework',

     SetDescription
 => 'set_description',

     SetEndTableOutputAction
 => 'set_end_table_output_action',

     SetFileEnd
 => 'set_file_end',

     SetFileStart
 => 'set_file_start',

     SetFormat
 => 'set_format',

     SetHeaderEnd
 => 'set_header_end',

     SetHeaderLine
 => 'set_header_line',

     SetHeaderOutputAction
 => 'set_header_output_action',

     SetHeaderRowEnd
 => 'set_header_row_end',

     SetHeaderRowStart
 => 'set_header_row_start',

     SetHeaderStart
 => 'set_header_start',

     SetHeaderTextsRef
 => 'set_header_texts_ref',

     SetHorizontalSeparationBoldChar
 => 'set_horizontal_separation_bold_char',

     SetHorizontalSeparationChar
 => 'set_horizontal_separation_char',

     SetHorizontalSeparationColumnSeparator
 => 'set_horizontal_separation_column_separator',

     SetHorizontalSeparationEnd
 => 'set_horizontal_separation_end',

     SetHorizontalSeparationStart
 => 'set_horizontal_separation_start',

     SetItalics
 => 'set_italics',

     SetLeft
 => 'set_left',

     SetMaxColWidth
 => 'set_max_col_width',

     SetMaxColumnIdx
 => 'set_max_column_idx',

     SetMaxRows
 => 'set_max_rows',

     SetName
 => 'set_name',

     SetPageEnd
 => 'set_page_end',

     SetPageStart
 => 'set_page_start',

     SetPrename
 => 'set_prename',

     SetRight
 => 'set_right',

     SetRowEnd
 => 'set_row_end',

     SetRowGroupChangesAction
 => 'set_row_group_changes_action',

     SetRowOutputAction
 => 'set_row_output_action',

     SetRowStart
 => 'set_row_start',

     SetSeparatorLine
 => 'set_separator_line',

     SetStartTableOutputAction
 => 'set_start_table_output_action',

     SetSurname
 => 'set_surname',

     SetTableEnd
 => 'set_table_end',

     SetTableStart
 => 'set_table_start',

     SetTableTopText
 => 'set_table_top_text',

     SetTime
 => 'set_time',

     SetVerbose
 => 'set_verbose',

     Store
 => 'store',

     UseDefaultConfiguratorCreators
 => 'use_default_configurator_creators',

     Verbose
 => 'verbose',

     WriteAll
 => 'write_all',

);
				}

1;
