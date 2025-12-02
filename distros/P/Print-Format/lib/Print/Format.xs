#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

void export_proto (CV * cb, char * pkg, int pkg_len, char * method, int method_len, char * proto) {
	dTHX;
	int name_len = pkg_len + method_len + 3;
	char *name = (char *)malloc(name_len);
	snprintf(name, name_len, "%s::%s", pkg, method);
	newXSproto(name, cb, __FILE__, proto);
	free(name);
}

bool is_cjk_codepoint(unsigned int codepoint) {
	return (codepoint >= 0x1100 && codepoint <= 0x115F) ||
		(codepoint >= 0x2E80 && codepoint <= 0x2EFF) ||
		(codepoint >= 0x2F00 && codepoint <= 0x2FDF) ||
		(codepoint >= 0x3000 && codepoint <= 0x303F) ||
		(codepoint >= 0x3040 && codepoint <= 0x309F) ||
		(codepoint >= 0x30A0 && codepoint <= 0x30FF) ||
		(codepoint >= 0x3100 && codepoint <= 0x312F) ||
		(codepoint >= 0x3130 && codepoint <= 0x318F) ||
		(codepoint >= 0x3200 && codepoint <= 0x32FF) ||
		(codepoint >= 0x3400 && codepoint <= 0x4DBF) ||
		(codepoint >= 0x4E00 && codepoint <= 0x9FFF) ||
		(codepoint >= 0xF900 && codepoint <= 0xFAFF);
}

bool is_decorative_line(const char *line) {
	size_t len = strlen(line);
	if (len == 0) return false;
	char first = line[0];
	if (first != '*' && first != '|' && first != '-') return false;
	return strspn(line, &first) == len;
}

char* trim_line(char *line) {
	char *end = line + strlen(line) - 1;
	while (end > line && (*end == ' ' || *end == '\t' || *end == '\r')) {
		*end = '\0';
		end--;
	}
	return line;
}

char** split_lines(const char *format_str, STRLEN len, int *line_count) {
	int capacity = 10;
	char **lines = (char**)malloc(capacity * sizeof(char*));
	*line_count = 0;
	
	char *line_start = (char*)format_str;
	char *current = (char*)format_str;
	
	while (current <= format_str + len) {
		if (*current == '\n' || current == format_str + len) {
			STRLEN line_len = current - line_start;
			if (line_len > 0) {
				char *line_copy = (char*)malloc(line_len + 1);
				strncpy(line_copy, line_start, line_len);
				line_copy[line_len] = '\0';
				trim_line(line_copy);
				
				if (strlen(line_copy) > 0) {
					if (*line_count >= capacity) {
						capacity *= 2;
						lines = (char**)realloc(lines, capacity * sizeof(char*));
					}
					lines[(*line_count)++] = line_copy;
				} else {
					free(line_copy);
				}
			}
			line_start = current + 1;
		}
		current++;
	}
	return lines;
}

HV* parse_raw_format (SV *format_sv) {
	dTHX;
	STRLEN len;
	char *format_str = SvPV(format_sv, len);
	
	HV *parsed = newHV();
	AV *line_pairs = newAV();
	
	int line_count = 0;
	char **lines = split_lines(format_str, len, &line_count);
	
	int section_num = 0;
	int i = 0;
	while (i < line_count) {
		if (strcmp(lines[i], "=") == 0) {
			section_num++;
			i++;
			continue;
		}
		if (is_decorative_line(lines[i])) {
			i++;
			continue;
		}
		
		if (i + 1 < line_count) {
			char *spec_line = lines[i];
			char *content_line = lines[i + 1];
			
			HV *pair = newHV();
			hv_store(pair, "section", 7, newSViv(section_num), 0);
			hv_store(pair, "spec_raw", 8, newSVpv(spec_line, 0), 0);
			hv_store(pair, "content_raw", 11, newSVpv(content_line, 0), 0);
			
			AV *spec_fields = newAV();
			bool line_repeat = false;
			
			char *line_end = spec_line + strlen(spec_line) - 1;
			while (line_end > spec_line && (*line_end == ' ' || *line_end == '\t')) line_end--;
			if (line_end > spec_line && *line_end == '~' && *(line_end - 1) == '~') {
				line_repeat = true;
			}
			
			char *pos = spec_line;
			while (*pos) {
				if (*pos == '@') {
					pos++;
					if (*pos == '<' || *pos == '>' || *pos == '|' || *pos == '^' || *pos == '*') {
						HV *field = newHV();
						char type = *pos;
						pos++;
						
						while (*pos && *pos == type) {
							pos++;
						}
						
						int percentage = 0;
						if (isdigit(*pos)) {
							percentage = atoi(pos);
							while (isdigit(*pos)) pos++;
						}
						
						bool word_break = false;
						if (*pos == ',') {
							word_break = true;
							pos++;
						}
						
						bool connect_next = false;
						if (*pos == '.') {
							connect_next = true;
							pos++;
						}
						
						bool repeat_field = false;
						if (*pos == '~' && *(pos + 1) == '~') {
							char *check_end = pos + 2;
							while (*check_end && (*check_end == ' ' || *check_end == '\t')) check_end++;
							if (*check_end == '\0') {
								line_repeat = true;
							} else {
								repeat_field = true;
							}
							pos += 2;
						}
						
						hv_store(field, "type", 4, newSVpvf("%c", type), 0);
						hv_store(field, "percentage", 10, newSViv(percentage), 0);
						hv_store(field, "repeat_field", 12, newSViv(repeat_field), 0);
						hv_store(field, "connect_next", 12, newSViv(connect_next), 0);
						hv_store(field, "word_break", 10, newSViv(word_break), 0);
						hv_store(field, "has_at_prefix", 13, newSViv(1), 0);
						
						av_push(spec_fields, newRV_noinc((SV*)field));
					}
			} else if (*pos == '<' || *pos == '>' || *pos == '|' || *pos == '^' || *pos == '*') {
				HV *field = newHV();
				char type = *pos;
				pos++;
				
				if (type == '^') {
					while (*pos && (*pos == '^' || *pos == '<')) {
						pos++;
					}
				} else {
					while (*pos && *pos == type) {
						pos++;
					}
				}
				
				int percentage = 0;
				if (isdigit(*pos)) {
					percentage = atoi(pos);
					while (isdigit(*pos)) pos++;
				}
				
				bool word_break = false;
				if (*pos == ',') {
					word_break = true;
					pos++;
				}
				
				bool connect_next = false;
				if (*pos == '.') {
					connect_next = true;
					pos++;
				}
				
				bool repeat_field = false;
				if (*pos == '~' && *(pos + 1) == '~') {
					char *check_end = pos + 2;
					while (*check_end && (*check_end == ' ' || *check_end == '\t')) check_end++;
					if (*check_end == '\0') {
						line_repeat = true;
					} else {
						repeat_field = true;
					}
					pos += 2;
				}
				
				hv_store(field, "type", 4, newSVpvf("%c", type), 0);
				hv_store(field, "percentage", 10, newSViv(percentage), 0);
				hv_store(field, "repeat_field", 12, newSViv(repeat_field), 0);
				hv_store(field, "connect_next", 12, newSViv(connect_next), 0);
				hv_store(field, "has_at_prefix", 13, newSViv(0), 0);
				hv_store(field, "word_break", 10, newSViv(word_break), 0);
				
				av_push(spec_fields, newRV_noinc((SV*)field));
				} else {
					pos++;
				}
			}
			
			hv_store(pair, "repeat_line", 11, newSViv(line_repeat), 0);
			
			AV *content_elements = newAV();
			pos = content_line;
			
			bool has_variables = false;
			char *check_pos = content_line;
			while (*check_pos) {
				if (*check_pos == '$' || *check_pos == '&' || *check_pos == '@') {
					has_variables = true;
					break;
				}
				check_pos++;
			}
			
			if (!has_variables) {
				HV *element = newHV();
				hv_store(element, "type", 4, newSVpv("text", 0), 0);
				hv_store(element, "content", 7, newSVpv(content_line, 0), 0);
				av_push(content_elements, newRV_noinc((SV*)element));
			} else {
			while (*pos) {
				if (*pos == '&') {
					pos++;
					char *name_start = pos;
					while (*pos && (isalnum(*pos) || *pos == '_')) pos++;
					if (pos > name_start) {
						STRLEN name_len = pos - name_start;
						char *name = (char*)malloc(name_len + 1);
						strncpy(name, name_start, name_len);
						name[name_len] = '\0';
						
						HV *element = newHV();
						hv_store(element, "type", 4, newSVpv("callback", 0), 0);
						hv_store(element, "name", 4, newSVpv(name, 0), 0);
						av_push(content_elements, newRV_noinc((SV*)element));
						free(name);
					}
					
					if (isspace(*pos)) {
						while (*pos && isspace(*pos)) pos++;
					}
				} else if (*pos == '$') {
					pos++;
					char *key_start = pos;
					while (*pos && (isalnum(*pos) || *pos == '_')) pos++;
					if (pos > key_start) {
						STRLEN key_len = pos - key_start;
						char *key = (char*)malloc(key_len + 1);
						strncpy(key, key_start, key_len);
						key[key_len] = '\0';
						
						HV *element = newHV();
						hv_store(element, "type", 4, newSVpv("param", 0), 0);
						hv_store(element, "key", 3, newSVpv(key, 0), 0);
						av_push(content_elements, newRV_noinc((SV*)element));
						free(key);
					}
					
					if (isspace(*pos)) {
						while (*pos && isspace(*pos)) pos++;
					}
				} else if (*pos == '@') {
					pos++;
					
					char *prefix = NULL;
					if (*pos == '[') {
						pos++;
						char *bracket_start = pos;
						while (*pos && *pos != ']') pos++;
						if (*pos == ']') {
							STRLEN bracket_len = pos - bracket_start;
							prefix = (char*)malloc(bracket_len + 1);
							strncpy(prefix, bracket_start, bracket_len);
							prefix[bracket_len] = '\0';
							pos++;
						}
					}
					
					char *array_start = pos;
					while (*pos && (isalnum(*pos) || *pos == '_')) pos++;
					
					if (pos > array_start) {
						STRLEN array_len = pos - array_start;
						char *array_name = (char*)malloc(array_len + 1);
						strncpy(array_name, array_start, array_len);
						array_name[array_len] = '\0';
						
						HV *element = newHV();
						hv_store(element, "type", 4, newSVpv("array", 0), 0);
						hv_store(element, "name", 4, newSVpv(array_name, 0), 0);
						
						if (prefix) {
							hv_store(element, "prefix", 6, newSVpv(prefix, 0), 0);
							free(prefix);
						}
						
						if (*pos == '[') {
							pos++;
							char *bracket_start = pos;
							while (*pos && *pos != ']') pos++;
							if (*pos == ']') {
								STRLEN bracket_len = pos - bracket_start;
								char *join_char = (char*)malloc(bracket_len + 1);
								strncpy(join_char, bracket_start, bracket_len);
								join_char[bracket_len] = '\0';
								
								hv_store(element, "join_char", 9, newSVpv(join_char, 0), 0);
								free(join_char);
								pos++;
							}
						}
						
						av_push(content_elements, newRV_noinc((SV*)element));
						free(array_name);
					}
					
					if (isspace(*pos)) {
						while (*pos && isspace(*pos)) pos++;
					}
				} else {
					if (*pos == '[') {
						char *bracket_start = pos + 1;
						char *bracket_end = bracket_start;
						while (*bracket_end && *bracket_end != ']') bracket_end++;
						
						if (*bracket_end == ']' && *(bracket_end + 1) == '@') {
							STRLEN prefix_len = bracket_end - bracket_start;
							char *prefix = (char*)malloc(prefix_len + 1);
							strncpy(prefix, bracket_start, prefix_len);
							prefix[prefix_len] = '\0';
							
							pos = bracket_end + 2;
							
							char *array_start = pos;
							while (*pos && (isalnum(*pos) || *pos == '_')) pos++;
							
							if (pos > array_start) {
								STRLEN array_len = pos - array_start;
								char *array_name = (char*)malloc(array_len + 1);
								strncpy(array_name, array_start, array_len);
								array_name[array_len] = '\0';
								
								HV *element = newHV();
								hv_store(element, "type", 4, newSVpv("array", 0), 0);
								hv_store(element, "name", 4, newSVpv(array_name, 0), 0);
								hv_store(element, "prefix", 6, newSVpv(prefix, 0), 0);
								
								if (*pos == '[') {
									pos++;
									char *join_start = pos;
									while (*pos && *pos != ']') pos++;
									if (*pos == ']') {
										STRLEN join_len = pos - join_start;
										char *join_char = (char*)malloc(join_len + 1);
										strncpy(join_char, join_start, join_len);
										join_char[join_len] = '\0';
										
										hv_store(element, "join_char", 9, newSVpv(join_char, 0), 0);
										free(join_char);
										pos++;
									}
								}
								
								av_push(content_elements, newRV_noinc((SV*)element));
								free(array_name);
							}
							free(prefix);
							
							if (isspace(*pos)) {
								while (*pos && isspace(*pos)) pos++;
							}
							continue;
						}
					}
					
					char *text_start = pos;
					while (*pos && *pos != '&' && *pos != '$' && *pos != '@' && 
						   !(*pos == '[' && strchr(pos, ']') && strchr(pos, '@'))) pos++;
					
					if (pos > text_start) {
						STRLEN text_len = pos - text_start;
						char *text = (char*)malloc(text_len + 1);
						strncpy(text, text_start, text_len);
						text[text_len] = '\0';
						
						char *trimmed = text;
						while (*trimmed && isspace(*trimmed)) trimmed++;
						char *end = text + strlen(text) - 1;
						while (end > text && isspace(*end)) {
							*end = '\0';
							end--;
						}
						
						if (strlen(trimmed) > 0) {
							HV *element = newHV();
							hv_store(element, "type", 4, newSVpv("text", 0), 0);
							hv_store(element, "content", 7, newSVpv(text, 0), 0);
							av_push(content_elements, newRV_noinc((SV*)element));
						}
						free(text);
					}
				}
			}
			}
			
			hv_store(pair, "spec_fields", 11, newRV_noinc((SV*)spec_fields), 0);
			hv_store(pair, "content_elements", 16, newRV_noinc((SV*)content_elements), 0);
			av_push(line_pairs, newRV_noinc((SV*)pair));
			
			i += 2;
		} else {
			i++;
		}
	}
	
	for (i = 0; i < line_count; i++) {
		free(lines[i]);
	}
	free(lines);
	
	hv_store(parsed, "line_pairs", 10, newRV_noinc((SV*)line_pairs), 0);
	hv_store(parsed, "total_sections", 14, newSViv(section_num), 0);
	
	return parsed;
}

char* strip_ansi_codes(const char *str) {
	dTHX;
	int len = strlen(str);
	char *result = (char*)malloc(len + 1);
	int out_pos = 0;
	int i = 0;
	
	while (i < len) {
		if (str[i] == '\x1b' && i + 1 < len && str[i+1] == '[') {
			i += 2;
			while (i < len && str[i] != 'm') {
				i++;
			}
			if (i < len && str[i] == 'm') {
				i++;
			}
		} else {
			result[out_pos++] = str[i++];
		}
	}
	
	result[out_pos] = '\0';
	return result;
}

int utf8_display_width(const char *str, int byte_len) {
	dTHX;
	char *stripped = strip_ansi_codes(str);
	int stripped_len = strlen(stripped);
	
	int width = 0;
	int i = 0;
	
	while (i < stripped_len) {
		unsigned char c = (unsigned char)stripped[i];
		
		if (c < 0x80) {
			width++;
			i++;
		} else if (c < 0xC0) {
			i++;
		} else if (c < 0xE0) {
			width++;
			i += 2;
		} else if (c < 0xF0) {
			if (i + 2 < stripped_len) {
				unsigned int codepoint = ((c & 0x0F) << 12) | 
										((stripped[i+1] & 0x3F) << 6) | 
										(stripped[i+2] & 0x3F);
				width += is_cjk_codepoint(codepoint) ? 2 : 1;
			} else {
				width++;
			}
			i += 3;
		} else if (c < 0xF8) {
			width++;
			i += 4;
		} else {
			i++;
		}
	}
	
	free(stripped);
	return width;
}

char* truncate_to_width_word_aware(const char *text, int max_width) {
	dTHX;
	int byte_len = strlen(text);
	char *stripped = strip_ansi_codes(text);
	int stripped_len = strlen(stripped);
	
	int current_width = 0;
	int orig_pos = 0;
	int stripped_pos = 0;
	int last_space_orig_pos = -1;
	int last_space_width = 0;
	
	while (orig_pos < byte_len && stripped_pos < stripped_len && current_width < max_width) {
		if (text[orig_pos] == '\x1b' && orig_pos + 1 < byte_len && text[orig_pos+1] == '[') {
			orig_pos += 2;
			while (orig_pos < byte_len && text[orig_pos] != 'm') {
				orig_pos++;
			}
			if (orig_pos < byte_len && text[orig_pos] == 'm') {
				orig_pos++;
			}
			continue;
		}
		
		if (stripped[stripped_pos] == ' ' || stripped[stripped_pos] == '\t') {
			last_space_orig_pos = orig_pos;
			last_space_width = current_width;
		}
		
		unsigned char c = (unsigned char)stripped[stripped_pos];
		int char_width = 1;
		int char_bytes = 1;
		
		if (c < 0x80) {
			char_width = 1;
			char_bytes = 1;
		} else if (c < 0xC0) {
			stripped_pos++;
			orig_pos++;
			continue;
		} else if (c < 0xE0) {
			char_width = 1;
			char_bytes = 2;
		} else if (c < 0xF0) {
			if (stripped_pos + 2 < stripped_len) {
				unsigned int codepoint = ((c & 0x0F) << 12) | 
										((stripped[stripped_pos+1] & 0x3F) << 6) | 
										(stripped[stripped_pos+2] & 0x3F);
				char_width = is_cjk_codepoint(codepoint) ? 2 : 1;
			} else {
				char_width = 1;
			}
			char_bytes = 3;
		} else {
			char_width = 1;
			char_bytes = 4;
		}
		
		if (current_width + char_width <= max_width) {
			current_width += char_width;
			stripped_pos += char_bytes;
			orig_pos += char_bytes;
		} else {
			break;
		}
	}
	
	if (last_space_orig_pos >= 0 && stripped_pos < stripped_len && current_width >= max_width) {
		orig_pos = last_space_orig_pos;
	}
	
	while (orig_pos < byte_len) {
		if (text[orig_pos] == '\x1b' && orig_pos + 1 < byte_len && text[orig_pos+1] == '[') {
			orig_pos += 2;
			while (orig_pos < byte_len && text[orig_pos] != 'm') {
				orig_pos++;
			}
			if (orig_pos < byte_len && text[orig_pos] == 'm') {
				orig_pos++;
			}
		} else {
			break;
		}
	}
	
	char *result = (char*)malloc(orig_pos + 1);
	strncpy(result, text, orig_pos);
	result[orig_pos] = '\0';
	free(stripped);
	return result;
}

char* truncate_to_width(const char *text, int max_width) {
	dTHX;
	int byte_len = strlen(text);
	char *stripped = strip_ansi_codes(text);
	int stripped_len = strlen(stripped);
	
	int current_width = 0;
	int orig_pos = 0;
	int stripped_pos = 0;
	
	while (orig_pos < byte_len && stripped_pos < stripped_len && current_width < max_width) {
		if (text[orig_pos] == '\x1b' && orig_pos + 1 < byte_len && text[orig_pos+1] == '[') {
			orig_pos += 2;
			while (orig_pos < byte_len && text[orig_pos] != 'm') {
				orig_pos++;
			}
			if (orig_pos < byte_len && text[orig_pos] == 'm') {
				orig_pos++;
			}
			continue;
		}
		
		unsigned char c = (unsigned char)stripped[stripped_pos];
		int char_width = 1;
		int char_bytes = 1;
		
		if (c < 0x80) {
			char_width = 1;
			char_bytes = 1;
		} else if (c < 0xC0) {
			stripped_pos++;
			orig_pos++;
			continue;
		} else if (c < 0xE0) {
			char_width = 1;
			char_bytes = 2;
		} else if (c < 0xF0) {
			if (stripped_pos + 2 < stripped_len) {
				unsigned int codepoint = ((c & 0x0F) << 12) | 
										((stripped[stripped_pos+1] & 0x3F) << 6) | 
										(stripped[stripped_pos+2] & 0x3F);
				char_width = is_cjk_codepoint(codepoint) ? 2 : 1;
			} else {
				char_width = 1;
			}
			char_bytes = 3;
		} else {
			char_width = 1;
			char_bytes = 4;
		}
		
		if (current_width + char_width <= max_width) {
			current_width += char_width;
			stripped_pos += char_bytes;
			orig_pos += char_bytes;
		} else {
			break;
		}
	}
	
	while (orig_pos < byte_len) {
		if (text[orig_pos] == '\x1b' && orig_pos + 1 < byte_len && text[orig_pos+1] == '[') {
			orig_pos += 2;
			while (orig_pos < byte_len && text[orig_pos] != 'm') {
				orig_pos++;
			}
			if (orig_pos < byte_len && text[orig_pos] == 'm') {
				orig_pos++;
			}
		} else {
			break;
		}
	}
	
	char *result = (char*)malloc(orig_pos + 1);
	strncpy(result, text, orig_pos);
	result[orig_pos] = '\0';
	free(stripped);
	return result;
}

char* process_format(SV *self_ref, HV *params) {
	dTHX;
	
	if (!SvROK(self_ref)) {
		croak("process_format: first argument must be a reference");
	}
	
	HV *self = (HV*)SvRV(self_ref);
	if (SvTYPE(self) != SVt_PVHV) {
		croak("process_format: first argument must be a hash reference");
	}
	
	SV **width_sv = hv_fetch(self, "width", 5, 0);
	int max_width = width_sv && *width_sv ? SvIV(*width_sv) : 80;
	
	SV **format_sv = hv_fetch(self, "format", 6, 0);
	if (!format_sv || !*format_sv || !SvROK(*format_sv)) {
		return NULL;
	}
	
	HV *format_data = (HV*)SvRV(*format_sv);
	SV **line_pairs_sv = hv_fetch(format_data, "line_pairs", 10, 0);
	if (!line_pairs_sv || !*line_pairs_sv || !SvROK(*line_pairs_sv)) {
		return NULL;
	}
	
	AV *line_pairs = (AV*)SvRV(*line_pairs_sv);
	int num_pairs = av_len(line_pairs) + 1;
	
	char *result = (char*)malloc(max_width * num_pairs * 10); 
	result[0] = '\0';
	int result_len = 0;
	int result_capacity = max_width * num_pairs * 10;
	
	HV *caller_stash = CopSTASH(PL_curcop);
	char *caller_pkg = HvNAME(caller_stash);
	
	HV *mutable_params = newHV();
	HE *entry;
	hv_iterinit(params);
	while ((entry = hv_iternext(params))) {
		I32 keylen;
		char *key = hv_iterkey(entry, &keylen);
		SV *val = hv_iterval(params, entry);
		hv_store(mutable_params, key, keylen, newSVsv(val), 0);
	}
	
	int array_item_idx = 0;
	int row_idx = 0;
	
	for (int pair_idx = 0; pair_idx < num_pairs; pair_idx++) {
		SV **pair_sv = av_fetch(line_pairs, pair_idx, 0);
		if (!pair_sv || !*pair_sv || !SvROK(*pair_sv)) continue;
		
		HV *pair = (HV*)SvRV(*pair_sv);
		
		SV **repeat_line_sv = hv_fetch(pair, "repeat_line", 11, 0);
		bool repeat_line = repeat_line_sv && *repeat_line_sv && SvIV(*repeat_line_sv);
		
		SV **spec_fields_sv = hv_fetch(pair, "spec_fields", 11, 0);
		SV **content_elements_sv = hv_fetch(pair, "content_elements", 16, 0);
		
		if (!spec_fields_sv || !*spec_fields_sv || !SvROK(*spec_fields_sv) ||
			!content_elements_sv || !*content_elements_sv || !SvROK(*content_elements_sv)) {
			if (mutable_params) SvREFCNT_dec((SV*)mutable_params);
			continue;
		}
		
		AV *spec_fields = (AV*)SvRV(*spec_fields_sv);
		AV *content_elements = (AV*)SvRV(*content_elements_sv);
		
		int num_fields = av_len(spec_fields) + 1;
		int num_elements = av_len(content_elements) + 1;
		
	bool has_content = true;
	row_idx = 0;
	array_item_idx = 0;
	
	typedef struct {
		char *remaining_content;
		int field_idx;
		int element_idx;
		bool has_remaining;
	} FieldRepeatState;
	
	FieldRepeatState *field_repeat_states = (FieldRepeatState*)calloc(num_fields, sizeof(FieldRepeatState));
	for (int i = 0; i < num_fields; i++) {
		field_repeat_states[i].remaining_content = NULL;
		field_repeat_states[i].field_idx = i;
		field_repeat_states[i].element_idx = -1;
		field_repeat_states[i].has_remaining = false;
	}
	
	while (has_content || !repeat_line) {
		bool any_content_consumed = false;
		bool has_field_repeat_content = false;
		array_item_idx = 0;  
		
		for (int i = 0; i < num_fields; i++) {
			if (field_repeat_states[i].has_remaining) {
				has_field_repeat_content = true;
				break;
			}
		}
	
		char **element_values = (char**)malloc(num_elements * sizeof(char*));
		int element_idx = 0;
		
		for (int i = 0; i < num_elements; i++) {
				element_values[i] = NULL;
				SV **element_sv = av_fetch(content_elements, i, 0);
				if (!element_sv || !*element_sv || !SvROK(*element_sv)) continue;
				
				HV *element = (HV*)SvRV(*element_sv);
				SV **type_sv = hv_fetch(element, "type", 4, 0);
				if (!type_sv || !*type_sv) continue;
				
				char *type = SvPV_nolen(*type_sv);
			
			if (strcmp(type, "text") == 0) {
				SV **content_sv = hv_fetch(element, "content", 7, 0);
				if (content_sv && *content_sv) {
					element_values[i] = strdup(SvPV_nolen(*content_sv));
				}
			} else if (strcmp(type, "param") == 0) {
				SV **key_sv = hv_fetch(element, "key", 3, 0);
				if (key_sv && *key_sv) {
					char *key = SvPV_nolen(*key_sv);
					SV **param_sv = hv_fetch(mutable_params, key, strlen(key), 0);
					if (param_sv && *param_sv) {
						element_values[i] = strdup(SvPV_nolen(*param_sv));
					} else {
						element_values[i] = strdup("");
					}
				}
			} else if (strcmp(type, "callback") == 0) {
				SV **name_sv = hv_fetch(element, "name", 4, 0);
				if (name_sv && *name_sv && caller_pkg) {
					char *cb_name = SvPV_nolen(*name_sv);
					
					dSP;
					ENTER;
					SAVETMPS;
					PUSHMARK(SP);
					
					XPUSHs(sv_2mortal(newRV_inc((SV*)params)));
					PUTBACK;
					
					int full_name_len = strlen(caller_pkg) + strlen(cb_name) + 3;
					char *full_name = (char*)malloc(full_name_len);
					snprintf(full_name, full_name_len, "%s::%s", caller_pkg, cb_name);
					
					int count = call_pv(full_name, G_SCALAR);
					SPAGAIN;
					
					if (count > 0) {
						SV *result_sv = POPs;
						if (SvOK(result_sv)) {
							element_values[i] = strdup(SvPV_nolen(result_sv));
						} else {
							element_values[i] = strdup("");
						}
					} else {
						element_values[i] = strdup("");
					}
					
					PUTBACK;
					FREETMPS;
					LEAVE;
					free(full_name);
				}
			} else if (strcmp(type, "array") == 0) {
				if (has_field_repeat_content) {
					element_values[i] = strdup("");
				} else {
					element_values[i] = strdup("__ARRAY_MARKER__");
				}
			}
			
			if (!element_values[i]) {
				element_values[i] = strdup("");
			}
		}
		
		int buffer_size = max_width * 3;
		char *line_buffer = (char*)malloc(buffer_size + 1);
		memset(line_buffer, ' ', max_width);
		line_buffer[max_width] = '\0';
		
		int current_pos = 0;
		int visual_pos = 0;
		element_idx = 0;
		char *current_join_char = NULL;
		
		char *array_join_char = NULL;
		for (int i = 0; i < num_elements; i++) {
			SV **elem_sv = av_fetch(content_elements, i, 0);
			if (elem_sv && *elem_sv && SvROK(*elem_sv)) {
				HV *elem = (HV*)SvRV(*elem_sv);
				SV **elem_type_sv = hv_fetch(elem, "type", 4, 0);
				if (elem_type_sv && *elem_type_sv && strcmp(SvPV_nolen(*elem_type_sv), "array") == 0) {
					SV **join_sv = hv_fetch(elem, "join_char", 9, 0);
					if (join_sv && *join_sv) {
						array_join_char = SvPV_nolen(*join_sv);
					}
					break;
				}
			}
		}
		
		int saved_space = 0;
		for (int field_idx = 0; field_idx < num_fields; field_idx++) {
		SV **field_sv = av_fetch(spec_fields, field_idx, 0);
		if (!field_sv || !*field_sv || !SvROK(*field_sv)) continue;
		
		HV *field = (HV*)SvRV(*field_sv);
		SV **type_sv = hv_fetch(field, "type", 4, 0);
		SV **percentage_sv = hv_fetch(field, "percentage", 10, 0);
		SV **connect_next_sv = hv_fetch(field, "connect_next", 12, 0);
		SV **repeat_field_sv = hv_fetch(field, "repeat_field", 12, 0);
		SV **word_break_sv = hv_fetch(field, "word_break", 10, 0);
		
		if (!type_sv || !*type_sv || !percentage_sv || !*percentage_sv) continue;
		
		char *field_type = SvPV_nolen(*type_sv);
		int percentage = SvIV(*percentage_sv);
		bool connect_next = connect_next_sv && *connect_next_sv && SvIV(*connect_next_sv);
		bool repeat_field = repeat_field_sv && *repeat_field_sv && SvIV(*repeat_field_sv);
		bool word_break = word_break_sv && *word_break_sv && SvIV(*word_break_sv);
		int field_width = percentage > 0 ? (max_width * percentage / 100) : max_width;
		field_width += saved_space;
		saved_space = 0;
		if (visual_pos + field_width > max_width) {
			field_width = max_width - visual_pos;
		}
		
		if (field_width <= 0) continue;
			
			current_join_char = NULL;
			
			SV **has_at_sv = hv_fetch(field, "has_at_prefix", 13, 0);
			bool has_at_prefix = (has_at_sv && *has_at_sv && SvIV(*has_at_sv));
			
			char *content = "";
			int matched_element_idx = -1;
			bool using_repeat_content = false;
			
			if (field_repeat_states[field_idx].has_remaining) {
				content = field_repeat_states[field_idx].remaining_content;
				matched_element_idx = field_repeat_states[field_idx].element_idx;
				using_repeat_content = true;
				element_idx = matched_element_idx;
			} else if (*field_type == '*') {
				if (element_idx < num_elements && element_values[element_idx]) {
					matched_element_idx = element_idx;
					content = element_values[element_idx];
				}
			} else if (*field_type == '^' || has_at_prefix) {
				for (int i = element_idx; i < num_elements; i++) {
					SV **elem_sv = av_fetch(content_elements, i, 0);
					if (elem_sv && *elem_sv && SvROK(*elem_sv)) {
						HV *elem = (HV*)SvRV(*elem_sv);
						SV **elem_type_sv = hv_fetch(elem, "type", 4, 0);
						if (elem_type_sv && *elem_type_sv) {
							char *elem_type = SvPV_nolen(*elem_type_sv);
							if (strcmp(elem_type, "param") == 0 || 
								strcmp(elem_type, "callback") == 0) {
								matched_element_idx = i;
								content = element_values[i];
								break;
							} else if (strcmp(elem_type, "array") == 0) {
								if (has_field_repeat_content && !field_repeat_states[field_idx].has_remaining && array_join_char && field_idx > 0) {
									current_join_char = array_join_char;
									break;
								}
								SV **name_sv = hv_fetch(elem, "name", 4, 0);
								if (name_sv && *name_sv) {
									char *array_name = SvPV_nolen(*name_sv);
									SV **array_sv = hv_fetch(params, array_name, strlen(array_name), 0);
									
									if (array_sv && *array_sv && SvROK(*array_sv) && SvTYPE(SvRV(*array_sv)) == SVt_PVAV) {
										AV *outer_array = (AV*)SvRV(*array_sv);
										int outer_len = av_len(outer_array) + 1;
										
										int use_row_idx = repeat_line ? row_idx : 0;
										
										if (use_row_idx < outer_len) {
											SV **row_sv = av_fetch(outer_array, use_row_idx, 0);
											
											AV *row_array = NULL;
											int row_len = 0;
											
											if (row_sv && *row_sv && SvROK(*row_sv) && SvTYPE(SvRV(*row_sv)) == SVt_PVAV) {
												row_array = (AV*)SvRV(*row_sv);
												row_len = av_len(row_array) + 1;
											} else {
												row_array = outer_array;
												row_len = outer_len;
												use_row_idx = array_item_idx;
											}
											
											if (array_item_idx < row_len) {
												SV **item_sv = av_fetch(row_array, array_item_idx, 0);
												if (item_sv && *item_sv) {
													SV **prefix_sv = hv_fetch(elem, "prefix", 6, 0);
													SV **join_sv = hv_fetch(elem, "join_char", 9, 0);
													char *prefix = (prefix_sv && *prefix_sv) ? SvPV_nolen(*prefix_sv) : "";
													char *join_char = (join_sv && *join_sv) ? SvPV_nolen(*join_sv) : "";
													
													char *item_str = SvPV_nolen(*item_sv);
													int content_len = strlen(prefix) + strlen(item_str) + 1;
													char *array_content = (char*)malloc(content_len);
													
													snprintf(array_content, content_len, "%s%s", prefix, item_str);
													
													matched_element_idx = i;
													content = array_content;
													current_join_char = (array_item_idx > 0 && strlen(join_char) > 0) ? join_char : NULL;
													array_item_idx++;
													break;
												}
											}
										}
									}
								}
							}
						}
					}
				}
			} else {
				for (int i = element_idx; i < num_elements; i++) {
					SV **elem_sv = av_fetch(content_elements, i, 0);
					if (elem_sv && *elem_sv && SvROK(*elem_sv)) {
						HV *elem = (HV*)SvRV(*elem_sv);
						SV **elem_type_sv = hv_fetch(elem, "type", 4, 0);
						if (elem_type_sv && *elem_type_sv) {
							char *elem_type = SvPV_nolen(*elem_type_sv);
							if (strcmp(elem_type, "text") == 0) {
								matched_element_idx = i;
								content = element_values[i];
								break;
							}
						}
					}
				}
			}
			
		bool is_mutable_field = (*field_type == '^');
		
		char *truncated = word_break ? truncate_to_width_word_aware(content, field_width) : truncate_to_width(content, field_width);
		int truncated_len = strlen(truncated);
		int content_width = utf8_display_width(truncated, strlen(truncated));
		
		char *remaining_after_truncate = NULL;
		if (repeat_field) {
			int skip_bytes = truncated_len;
			int content_len = strlen(content);
			
			if (word_break && skip_bytes < content_len) {
				while (skip_bytes < content_len && (content[skip_bytes] == ' ' || content[skip_bytes] == '\t')) {
					skip_bytes++;
				}
			}
			
			if (skip_bytes < content_len && strlen(content + skip_bytes) > 0) {
				remaining_after_truncate = strdup(content + skip_bytes);
			}
		}
			
			if (using_repeat_content) {
				if (field_repeat_states[field_idx].remaining_content) {
					free(field_repeat_states[field_idx].remaining_content);
					field_repeat_states[field_idx].remaining_content = NULL;
				}
				field_repeat_states[field_idx].remaining_content = remaining_after_truncate;
				field_repeat_states[field_idx].has_remaining = (remaining_after_truncate != NULL && strlen(remaining_after_truncate) > 0);
			} else if (remaining_after_truncate && strlen(remaining_after_truncate) > 0) {
				field_repeat_states[field_idx].remaining_content = remaining_after_truncate;
				field_repeat_states[field_idx].element_idx = matched_element_idx;
				field_repeat_states[field_idx].has_remaining = true;
			} else if (remaining_after_truncate) {
				free(remaining_after_truncate);
			}
			

			if (is_mutable_field && mutable_params && matched_element_idx >= 0 && matched_element_idx < num_elements) {
				SV **element_sv = av_fetch(content_elements, matched_element_idx, 0);
				if (element_sv && *element_sv && SvROK(*element_sv)) {
					HV *element = (HV*)SvRV(*element_sv);
					SV **type_sv = hv_fetch(element, "type", 4, 0);
					if (type_sv && *type_sv && strcmp(SvPV_nolen(*type_sv), "param") == 0) {
						SV **key_sv = hv_fetch(element, "key", 3, 0);
						if (key_sv && *key_sv) {
							char *key = SvPV_nolen(*key_sv);
							char *stripped_truncated = strip_ansi_codes(truncated);
							int stripped_truncated_len = strlen(stripped_truncated);
							free(stripped_truncated);
							
							char *content_stripped = strip_ansi_codes(content);
							int skip_bytes = 0;
							int chars_counted = 0;
							int content_len = strlen(content);
							
							while (skip_bytes < content_len && chars_counted < stripped_truncated_len) {
								if (content[skip_bytes] == '\x1b' && skip_bytes + 1 < content_len && content[skip_bytes+1] == '[') {
									skip_bytes += 2;
									while (skip_bytes < content_len && content[skip_bytes] != 'm') {
										skip_bytes++;
									}
									if (skip_bytes < content_len && content[skip_bytes] == 'm') {
										skip_bytes++;
									}
									continue;
								}
								
								unsigned char c = (unsigned char)content[skip_bytes];
								if (c < 0x80) {
									skip_bytes++;
								} else if (c < 0xC0) {
									skip_bytes++;
								} else if (c < 0xE0) {
									skip_bytes += 2;
								} else if (c < 0xF0) {
									skip_bytes += 3;
								} else {
									skip_bytes += 4;
								}
								chars_counted++;
							}
							
							free(content_stripped);
							
							char *new_content = content + skip_bytes;
							hv_store(mutable_params, key, strlen(key), newSVpv(new_content, 0), 0);
							if (skip_bytes > 0) {
								any_content_consumed = true;
							}
						}
					}
				}
			}
			
			int join_offset = 0;
			if (current_join_char && strlen(current_join_char) > 0) {
				int join_len = strlen(current_join_char);
				if (current_pos + join_len < max_width) {
					memcpy(line_buffer + current_pos, current_join_char, join_len);
					join_offset = join_len;
					if (current_pos + join_len < max_width) {
						line_buffer[current_pos + join_len] = ' ';
						join_offset++;
					}
				}
			}
			
			if (*field_type == '<') {
				memcpy(line_buffer + current_pos + join_offset, truncated, truncated_len);
		if (connect_next) {
			int visual_advance = join_offset + content_width;
			int byte_advance = join_offset + truncated_len;
			saved_space = field_width - visual_advance;
			current_pos += byte_advance;
			visual_pos += visual_advance;
		} else {
			current_pos += field_width;
			visual_pos += field_width;
		}
			} else if (*field_type == '^') {
				memcpy(line_buffer + current_pos + join_offset, truncated, truncated_len);
		if (connect_next) {
			int visual_advance = join_offset + content_width;
			int byte_advance = join_offset + truncated_len;
			saved_space = field_width - visual_advance;
			current_pos += byte_advance;
			visual_pos += visual_advance;
		} else {
			current_pos += field_width;
			visual_pos += field_width;
		}
			} else if (*field_type == '>') {
				if (connect_next) {
					int start_pos = current_pos + join_offset + field_width - join_offset - content_width;
					if (start_pos < current_pos + join_offset) start_pos = current_pos + join_offset;
					memcpy(line_buffer + start_pos, truncated, truncated_len);
					current_pos += field_width;
					visual_pos += field_width;
				} else {
					int start_pos = current_pos + join_offset + field_width - join_offset - content_width;
					if (start_pos < current_pos + join_offset) start_pos = current_pos + join_offset;
					memcpy(line_buffer + start_pos, truncated, truncated_len);
					current_pos += field_width;
					visual_pos += field_width;
				}
			} else if (*field_type == '|') {
				int available_width = field_width - join_offset;
				int left_pad = (available_width - content_width) / 2;
				int start_pos = current_pos + join_offset + left_pad;
				
				if (start_pos < current_pos + join_offset) start_pos = current_pos + join_offset;
				if (start_pos + truncated_len > current_pos + field_width) {
					start_pos = current_pos + field_width - truncated_len;
					if (start_pos < current_pos + join_offset) start_pos = current_pos + join_offset;
				}
				
				if (join_offset < field_width) {
					memset(line_buffer + current_pos + join_offset, ' ', field_width - join_offset);
				}
				if (truncated_len > 0 && start_pos + truncated_len <= current_pos + buffer_size) {
					memcpy(line_buffer + start_pos, truncated, truncated_len);
				}
				current_pos += field_width;
				visual_pos += field_width;
			} else if (*field_type == '*') {
				if (strlen(content) > 0) {
					int orig_content_len = strlen(content);
					int pos_in_field = 0;
					
					while (pos_in_field < field_width) {
						int chars_to_copy = (field_width - pos_in_field < orig_content_len) ? 
											field_width - pos_in_field : orig_content_len;
						memcpy(line_buffer + current_pos + pos_in_field, content, chars_to_copy);
						pos_in_field += chars_to_copy;
					}
				}
				current_pos += field_width;
				visual_pos += field_width;
			} else {
				memcpy(line_buffer + current_pos, truncated, truncated_len);
				current_pos += field_width;
				visual_pos += field_width;
			}
			
			free(truncated);
			
			if (*field_type != '^' && matched_element_idx >= 0 && !has_field_repeat_content) {
				bool is_array_element = false;
				if (matched_element_idx < num_elements) {
					SV **elem_sv = av_fetch(content_elements, matched_element_idx, 0);
					if (elem_sv && *elem_sv && SvROK(*elem_sv)) {
						HV *elem = (HV*)SvRV(*elem_sv);
						SV **elem_type_sv = hv_fetch(elem, "type", 4, 0);
						if (elem_type_sv && *elem_type_sv && strcmp(SvPV_nolen(*elem_type_sv), "array") == 0) {
							is_array_element = true;
						}
					}
				}
				
				if (!is_array_element) {
					element_idx = matched_element_idx + 1;
					current_join_char = NULL;
				}
			}
		} 
		
		char *stripped_line = strip_ansi_codes(line_buffer);
		int visible_len = utf8_display_width(stripped_line, strlen(stripped_line));
		free(stripped_line);
		
		int output_bytes = 0;
		int visible_count = 0;
		int buf_len = strlen(line_buffer);
		
		while (output_bytes < buf_len && visible_count < max_width) {
			if (line_buffer[output_bytes] == '\x1b' && output_bytes + 1 < buf_len && line_buffer[output_bytes+1] == '[') {
				output_bytes += 2;
				while (output_bytes < buf_len && line_buffer[output_bytes] != 'm') {
					output_bytes++;
				}
				if (output_bytes < buf_len && line_buffer[output_bytes] == 'm') {
					output_bytes++;
				}
				continue;
			}
			
			unsigned char c = (unsigned char)line_buffer[output_bytes];
			if (c < 0x80) {
				output_bytes++;
			} else if (c < 0xC0) {
				output_bytes++;
			} else if (c < 0xE0) {
				output_bytes += 2;
			} else if (c < 0xF0) {
				output_bytes += 3;
			} else {
				output_bytes += 4;
			}
			visible_count++;
		}
		
		if (result_len + output_bytes + 2 >= result_capacity) {
			result_capacity *= 2;
			result = (char*)realloc(result, result_capacity);
		}
		
		memcpy(result + result_len, line_buffer, output_bytes);
		result[result_len + output_bytes] = '\n';
		result[result_len + output_bytes + 1] = '\0';
		result_len += output_bytes + 1;
		
		free(line_buffer);
		for (int i = 0; i < num_elements; i++) {
			if (element_values[i]) free(element_values[i]);
		}
		free(element_values);
		
		bool has_field_repeat = false;
		for (int i = 0; i < num_fields; i++) {
			if (field_repeat_states[i].has_remaining) {
				has_field_repeat = true;
				break;
			}
		}
		
		if (has_field_repeat) {
			has_content = true;
			continue;
		}
		
		has_content = false;
		if (repeat_line) {
			for (int i = 0; i < num_elements; i++) {
				SV **element_sv = av_fetch(content_elements, i, 0);
				if (!element_sv || !*element_sv || !SvROK(*element_sv)) continue;
				
				HV *element = (HV*)SvRV(*element_sv);
				SV **type_sv = hv_fetch(element, "type", 4, 0);
				if (!type_sv || !*type_sv) continue;
				
				char *type = SvPV_nolen(*type_sv);
				if (strcmp(type, "array") == 0) {
					SV **name_sv = hv_fetch(element, "name", 4, 0);
					if (name_sv && *name_sv) {
						char *array_name = SvPV_nolen(*name_sv);
						SV **array_sv = hv_fetch(params, array_name, strlen(array_name), 0);
						if (array_sv && *array_sv && SvROK(*array_sv) && SvTYPE(SvRV(*array_sv)) == SVt_PVAV) {
							AV *outer_array = (AV*)SvRV(*array_sv);
							int outer_len = av_len(outer_array) + 1;
							
							if (row_idx + 1 < outer_len) {
								has_content = true;
								row_idx++;
								array_item_idx = 0;
								for (int j = 0; j < num_fields; j++) {
									if (field_repeat_states[j].remaining_content) {
										free(field_repeat_states[j].remaining_content);
										field_repeat_states[j].remaining_content = NULL;
									}
									field_repeat_states[j].has_remaining = false;
								}
								break;
							}
						}
					}
				}
			}
			
			if (!has_content && mutable_params && any_content_consumed) {
				for (int i = 0; i < num_elements; i++) {
					SV **element_sv = av_fetch(content_elements, i, 0);
					if (!element_sv || !*element_sv || !SvROK(*element_sv)) continue;
					
					HV *element = (HV*)SvRV(*element_sv);
					SV **type_sv = hv_fetch(element, "type", 4, 0);
					if (!type_sv || !*type_sv) continue;
					
					char *type = SvPV_nolen(*type_sv);
					if (strcmp(type, "param") == 0) {
						SV **key_sv = hv_fetch(element, "key", 3, 0);
						if (key_sv && *key_sv) {
							char *key = SvPV_nolen(*key_sv);
							SV **param_sv = hv_fetch(mutable_params, key, strlen(key), 0);
							if (param_sv && *param_sv && SvOK(*param_sv)) {
								char *remaining = SvPV_nolen(*param_sv);
								if (remaining && strlen(remaining) > 0) {
									has_content = true;
									break;
								}
							}
						}
					}
				}
			}
		}
		
		if (repeat_line && !has_content) break;
		if (!repeat_line && !has_field_repeat) break;
	
	}
	
	for (int i = 0; i < num_fields; i++) {
		if (field_repeat_states[i].remaining_content) {
			free(field_repeat_states[i].remaining_content);
		}
	}
	free(field_repeat_states);
	
}
	
	if (mutable_params) {
		SvREFCNT_dec((SV*)mutable_params);
	}
	
	return result;
}

MODULE = Print::Format  PACKAGE = Print::Format
PROTOTYPES: DISABLE

HV*
parse_format(SV *format_sv)
	CODE:
		RETVAL = parse_raw_format(format_sv);
	OUTPUT:
		RETVAL

void
form(...)
	PROTOTYPE: \[$]$
	CODE:
		SV *format_sv = ST(1);
		GV *gv = newGVgen("Print::Format");
		if (!GvIOp(gv)) {
			GvIOp(gv) = newIO();
		}
		HV *format_stash = gv_stashpv("Print::Format", GV_ADD);
		HV *tied_obj = newHV();
		hv_store(tied_obj, "format_raw", 10, SvREFCNT_inc(format_sv), 0);
		hv_store(tied_obj, "handle", 6, (SV*)GvIOp(gv), 0);
		hv_store(tied_obj, "width", 5, newSViv(100), 0);
		SV *tied_obj_ref = newRV_noinc((SV*)tied_obj);
		sv_bless(tied_obj_ref, format_stash);
		sv_magic((SV*)GvIOp(gv), tied_obj_ref, PERL_MAGIC_tiedscalar, NULL, 0);
		
		HV * format = parse_raw_format(format_sv);
		hv_store(tied_obj, "format", 6, newRV_noinc((SV*)format), 0);

		SV *rv = newRV_inc((SV*)gv);
		SV *self_ref = ST(0);
		if (SvROK(self_ref)) {
			SV *self = SvRV(self_ref);
			sv_setsv(self, rv);
		}
		XSRETURN(1);

int
OPEN(SV *self_ref, SV *type, SV *file, SV *width)
	CODE:
		if (!SvROK(self_ref)) {
			croak("OPEN: first argument must be a reference");
		}
		HV *self = (HV*)SvRV(self_ref);
		if (SvTYPE(self) != SVt_PVHV) {
			croak("OPEN: first argument must be a hash reference");
		}
		hv_store(self, "type", 4, newSVsv(type), 0);
		hv_store(self, "fh", 2, newSVsv(file), 0);
		hv_store(self, "width", 5, newSVsv(width), 0);
		SV **handle_sv = hv_fetch(self, "handle", 6, 0);
		SV **fh_sv = hv_fetch(self, "fh", 2, 0);
		SvREFCNT_inc(self);
		if (fh_sv && *fh_sv && SvOK(*fh_sv)) {
			if (SvPOK(*fh_sv)) {
				char *fh_name = SvPV_nolen(*fh_sv);
				if (strcmp(fh_name, "STDOUT") == 0 && handle_sv && *handle_sv) {
					GV * out = gv_fetchpv("main::STDOUT", GV_ADD, SVt_PVIO);
					if (GvIOp(out)) {
						hv_store(self, "original_io", 11, newRV_inc((SV*)GvIOp(out)), 0);
					}
					IO *io = (IO*)*handle_sv;
					GvIOp(out) = io;
				} else if (strcmp(fh_name, "STDERR") == 0 && handle_sv && *handle_sv) {
					GV * err = gv_fetchpv("main::STDERR", GV_ADD, SVt_PVIO);
					if (GvIOp(err)) {
						hv_store(self, "original_io", 11, newRV_inc((SV*)GvIOp(err)), 0);
					}
					IO *io = (IO*)*handle_sv;
					GvIOp(err) = io;
				} else {
					PerlIO *fh = PerlIO_open(fh_name, "w");
					if (!fh) {
						croak("OPEN: failed to open file: %s", fh_name);
					}
					if (handle_sv && *handle_sv) {
						IO *io = (IO*)*handle_sv;
						IoOFP(io) = fh;
						IoIFP(io) = fh;
					}
					SV *fh_sv_new = newRV_noinc((SV*)handle_sv && *handle_sv ? (SV*)*handle_sv : newSV(0));
					hv_store(self, "fh", 2, fh_sv_new, 0);
				}
			}
		}
		RETVAL = 1;
	OUTPUT:
		RETVAL

void
PRINT(SV *self_ref, ...)
	CODE:
		if (!SvROK(self_ref)) {
			croak("PRINT: first argument must be a reference");
		}
		HV *self = (HV*)SvRV(self_ref);
		if (SvTYPE(self) != SVt_PVHV) {
			croak("PRINT: first argument must be a hash reference");
		}
		SV **fh_sv = hv_fetch(self, "fh", 2, 0);
		if (!fh_sv || !*fh_sv) {
			croak("PRINT: no file handle found");
		}
		HV * params = newHV();
		int i;
		for (i = 1; i < items; i += 2) {
			if (i + 1 >= items) {
				croak("PRINT: odd number of arguments in key/value list");
			}
			STRLEN key_len;
			char *key = SvPV(ST(i), key_len);
			hv_store(params, key, key_len, newSVsv(ST(i + 1)), 0);
		}

		char *to_print = process_format(self_ref, params);
		if (to_print) {
			if (SvPOK(*fh_sv)) {
				if (strcmp(SvPV_nolen(*fh_sv), "STDOUT") == 0) {
					PerlIO *out = PerlIO_stdout();
					PerlIO_printf(out, "%s", to_print);
				} else if (strcmp(SvPV_nolen(*fh_sv), "STDERR") == 0) {
					PerlIO *err = PerlIO_stderr();
					PerlIO_printf(err, "%s", to_print);
				} else {
					croak("PRINT: unknown file handle name: %s", SvPV_nolen(*fh_sv));
				}
			} else {
				SV **handle_sv = hv_fetch(self, "handle", 6, 0);
				if (handle_sv && *handle_sv) {
					IO *io = (IO*)*handle_sv;
					PerlIO *fh = IoOFP(io);
					if (fh) {
						PerlIO_printf(fh, "%s", to_print);
					} else {
						croak("PRINT: file handle not opened");
					}
				} else {
					croak("PRINT: no IO handle found");
				}
			}
			free(to_print);
		}

void
CLOSE(SV *self_ref)
	CODE:
		dSP;
		ENTER;
		SAVETMPS;
		PUSHMARK(SP);
		XPUSHs(self_ref);
		PUTBACK;
		call_method("DESTROY", G_DISCARD);
		FREETMPS;
		LEAVE;

void
DESTROY(SV *self_ref)
	CODE:
		if (!SvROK(self_ref)) {
			croak("DESTROY: first argument must be a reference");
		}
		HV *self = (HV*)SvRV(self_ref);
		if (SvTYPE(self) != SVt_PVHV) {
			croak("DESTROY: first argument must be a hash reference");
		}
		SV **fh_sv = hv_fetch(self, "fh", 2, 0);
		if (fh_sv && *fh_sv && SvOK(*fh_sv)) {
			if (SvPOK(*fh_sv)) {
				char *fh_name = SvPV_nolen(*fh_sv);
				if (strcmp(fh_name, "STDOUT") == 0) {
					SV **orig_handle_sv = hv_fetch(self, "original_io", 11, 0);
					if (orig_handle_sv && *orig_handle_sv && SvROK(*orig_handle_sv)) {
						GV *out = gv_fetchpv("main::STDOUT", GV_ADD, SVt_PVIO);
						IO *orig_io = (IO*)SvRV(*orig_handle_sv);
						GvIOp(out) = orig_io;
					}
				} else if (strcmp(fh_name, "STDERR") == 0) {
					SV **orig_handle_sv = hv_fetch(self, "original_io", 11, 0);
					if (orig_handle_sv && *orig_handle_sv && SvROK(*orig_handle_sv)) {
						GV *err = gv_fetchpv("main::STDERR", GV_ADD, SVt_PVIO);
						IO *orig_io = (IO*)SvRV(*orig_handle_sv);
						GvIOp(err) = orig_io;
					}
				}
			} else {
				SV **handle_sv = hv_fetch(self, "handle", 6, 0);
				if (handle_sv && *handle_sv) {
					IO *io = (IO*)*handle_sv;
					PerlIO *fh = IoOFP(io);
					if (fh) {
						PerlIO_close(fh);
					}
				}
			}
		}

void
import(...)
    CODE:
 char *pkg = HvNAME((HV*)CopSTASH(PL_curcop));
	int pkg_len = strlen(pkg);
	STRLEN retlen;
	int i = 1;
	for (i = 1; i < items; i++) {
		char * ex = SvPV(ST(i), retlen);
		if (strcmp(ex, "all") == 0) {
			export_proto(XS_Print__Format_form, pkg, pkg_len, "form", 4, "\\[$]$");
		} else if (strcmp(ex, "form") == 0) {
			export_proto(XS_Print__Format_form, pkg, pkg_len, "form", 4, "\\[$]$");
		} else {
			croak("Unknown import: %s", ex);
		}
	}
