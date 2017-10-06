#include <stdlib.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "nsort.h"

char *get_next_chunk(const char *, int *, bool *);
bool isDigit(const char);
bool isAlpha(const char);

int _ncmp(const char *a, const char *b, int reverse, int use_locale) {
    int len_a = strlen(a);
    int len_b = strlen(b);
    int offset_a = 0;
    int offset_b = 0;
    bool is_digit_a = NULL;
    bool is_digit_b = NULL;
    bool is_fist_char_a_alpha = isAlpha(a[0]);
    bool is_fist_char_b_alpha = isAlpha(b[0]);
    int result = 0;

    if (!use_locale && is_fist_char_a_alpha && is_fist_char_b_alpha) {
        offset_a = 1;
        offset_b = 1;
        result = (a[0] < b[0]) ? -1 : (a[0] > b[0]);
    } else if (is_fist_char_a_alpha && isDigit(b[0])) {
        result = 1;
    } else if (isDigit(a[0]) && is_fist_char_b_alpha) {
        result = -1;
    }

    if (result == 0) {
        int chunk_a_int;
        int chunk_b_int;

        while (offset_a != len_a && offset_b != len_b) {
            char *chunk_a = get_next_chunk(a, &offset_a, &is_digit_a);
            char *chunk_b = get_next_chunk(b, &offset_b, &is_digit_b);
            bool is_last_chunk_a_digit = !is_digit_a;
            bool is_last_chunk_b_digit = !is_digit_b;

            if (is_last_chunk_a_digit == is_last_chunk_b_digit) {
                if (is_last_chunk_a_digit) {
                    chunk_a_int = atoi(chunk_a);
                    chunk_b_int = atoi(chunk_b);
                    result = (chunk_a_int < chunk_b_int) ? -1 : (chunk_a_int > chunk_b_int);
                } else if (use_locale) {
                    result = strcoll(chunk_a, chunk_b);
                } else {
                    result = strcmp(chunk_a, chunk_b);
                }
            } else {
                if (is_last_chunk_a_digit) {
                    result = -1;
                } else {
                    result = 1;
                }
            }

            free(chunk_a);
            free(chunk_b);

            if (result != 0) {
                break;
            } else if (offset_a == len_a) {
                result = -1;
            } else if (offset_b == len_b) {
                result = 1;
            }
        }
    }

    return reverse ? (-1 * result) : result;
}

char *get_next_chunk(const char *raw, int *offset, bool *is_digit) {
    if (*offset == 0) {
        *is_digit = isDigit(raw[0]);
    }

    int i;
    int len;
    int raw_len = strlen(raw);
    for (i = *offset; i < raw_len; i++) {
        bool c_is_digit = isDigit(raw[i]);

        if (c_is_digit != *is_digit) {
            *is_digit = c_is_digit;
            len = i - *offset;
            break;
        } else if (i == raw_len - 1) {
            len = raw_len - *offset;
            *is_digit = !*is_digit;
        }
    }

    char *chunk = malloc((len + 1) * sizeof(char));
    strncpy(chunk, raw + *offset, len);
    chunk[len] = '\0';
    *offset += len;

    return chunk;
}

bool isDigit(const char c) {
    return (c >= '0' && c <= '9');
}

bool isAlpha(const char c) {
    return ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'));
}
