#ifndef PSAML_TIME_H
#define PSAML_TIME_H

/* xs:dateTime, both ways, UTC only.
 *
 * Every timestamp SAML compares is an xs:dateTime: NotBefore,
 * NotOnOrAfter, IssueInstant, SessionNotOnOrAfter. The comparisons decide
 * whether a login is accepted, so the parse has to be exact and has to
 * refuse what it does not understand rather than approximate it.
 *
 * timegm is not portable: it is a GNU/BSD extension, absent on Windows
 * and not in any C standard. The alternative usually reached for is
 * mktime with TZ forced to UTC, which mutates process-global state and
 * is not thread-safe. So the conversion is arithmetic, using the
 * days-from-civil algorithm: exact for every year in range, no tables,
 * no locale, no globals.
 *
 * Accepted: [-]YYYY-MM-DDThh:mm:ss[.fraction][Z|(+|-)hh:mm]
 * Refused: a missing timezone (xs:dateTime allows it and calls the value
 * local, which is not a thing a protocol timestamp may be), a 24:00
 * end-of-day, and anything out of range. Leap seconds (ss == 60) are
 * refused: no identity provider emits one and accepting it would mean
 * deciding what instant it names.
 *
 * The fraction is parsed and discarded. Assertion lifetimes are minutes;
 * sub-second precision has no bearing on any comparison here, and
 * carrying it would only invite a rounding difference between the two
 * sides of one. */

#include <string.h>

/* Days from 1970-01-01 to y-m-d, proleptic Gregorian. Howard Hinnant's
 * days_from_civil: exact for the whole range, and the shift to a
 * March-based year is what removes the leap-day special case. */
PERL_STATIC_INLINE IV psaml_days_from_civil(IV y, unsigned m, unsigned d) {
  IV era, doe, yoe, doy, eyr;
  y -= (m <= 2);
  eyr = (y >= 0 ? y : y - 399);
  era = eyr / 400;
  yoe = y - era * 400;                                    /* [0, 399] */
  doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;   /* [0, 365] */
  doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;            /* [0, 146096] */
  return era * 146097 + doe - 719468;
}

/* The inverse, civil_from_days. */
PERL_STATIC_INLINE void psaml_civil_from_days(IV z, IV *y, unsigned *m, unsigned *d) {
  IV era, doe, yoe, doy, mp, yr;
  z += 719468;
  era = (z >= 0 ? z : z - 146096) / 146097;
  doe = z - era * 146097;                                  /* [0, 146096] */
  yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
  yr  = yoe + era * 400;
  doy = doe - (365 * yoe + yoe / 4 - yoe / 100);           /* [0, 365] */
  mp  = (5 * doy + 2) / 153;                               /* [0, 11] */
  *d  = (unsigned)(doy - (153 * mp + 2) / 5 + 1);          /* [1, 31] */
  *m  = (unsigned)(mp + (mp < 10 ? 3 : -9));               /* [1, 12] */
  *y  = yr + (*m <= 2);
}

PERL_STATIC_INLINE int psaml_is_leap(IV y) {
  return (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
}

PERL_STATIC_INLINE unsigned psaml_days_in_month(IV y, unsigned m) {
  static const unsigned len[13] =
    { 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 };
  if (m == 2 && psaml_is_leap(y)) return 29;
  return (m >= 1 && m <= 12) ? len[m] : 0;
}

PERL_STATIC_INLINE int psaml_digits(const char *p, STRLEN n, IV *out) {
  IV v = 0;
  STRLEN i;
  for (i = 0; i < n; i++) {
    if (p[i] < '0' || p[i] > '9') return 0;
    v = v * 10 + (p[i] - '0');
  }
  *out = v;
  return 1;
}

/* Parses into seconds since the epoch. Returns 1 on success, 0 on any
 * refusal, and never partially fills *out. */
PERL_STATIC_INLINE int psaml_time_parse(const char *s, STRLEN len, IV *out) {
  IV       y, mo, da, ho, mi, se, days;
  IV       offset = 0;
  STRLEN   i = 0;
  int      neg_year = 0;

  if (!s) return 0;
  if (i < len && s[i] == '-') { neg_year = 1; i++; }
  /* the year is at least four digits and may be longer, but not padded */
  {
    STRLEN start = i;
    while (i < len && s[i] >= '0' && s[i] <= '9') i++;
    if (i - start < 4) return 0;
    if (i - start > 4 && s[start] == '0') return 0;
    if (!psaml_digits(s + start, i - start, &y)) return 0;
  }
  if (neg_year) y = -y;
  if (i + 1 > len || s[i] != '-') return 0;
  i++;
  if (i + 2 > len || !psaml_digits(s + i, 2, &mo)) return 0;
  i += 2;
  if (i + 1 > len || s[i] != '-') return 0;
  i++;
  if (i + 2 > len || !psaml_digits(s + i, 2, &da)) return 0;
  i += 2;
  if (i + 1 > len || s[i] != 'T') return 0;
  i++;
  if (i + 2 > len || !psaml_digits(s + i, 2, &ho)) return 0;
  i += 2;
  if (i + 1 > len || s[i] != ':') return 0;
  i++;
  if (i + 2 > len || !psaml_digits(s + i, 2, &mi)) return 0;
  i += 2;
  if (i + 1 > len || s[i] != ':') return 0;
  i++;
  if (i + 2 > len || !psaml_digits(s + i, 2, &se)) return 0;
  i += 2;

  if (i < len && s[i] == '.') {          /* parsed and discarded */
    STRLEN start = ++i;
    while (i < len && s[i] >= '0' && s[i] <= '9') i++;
    if (i == start) return 0;            /* a '.' with no digits */
  }

  if (i >= len) return 0;                /* no timezone: refused */
  if (s[i] == 'Z') {
    i++;
  }
  else if (s[i] == '+' || s[i] == '-') {
    IV oh, om;
    int minus = (s[i] == '-');
    i++;
    if (i + 2 > len || !psaml_digits(s + i, 2, &oh)) return 0;
    i += 2;
    if (i + 1 > len || s[i] != ':') return 0;
    i++;
    if (i + 2 > len || !psaml_digits(s + i, 2, &om)) return 0;
    i += 2;
    if (oh > 14 || om > 59 || (oh == 14 && om != 0)) return 0;
    offset = oh * 3600 + om * 60;
    if (minus) offset = -offset;
  }
  else {
    return 0;
  }
  if (i != len) return 0;                /* trailing bytes */

  if (mo < 1 || mo > 12) return 0;
  if (da < 1 || (unsigned)da > psaml_days_in_month(y, (unsigned)mo)) return 0;
  if (ho > 23 || mi > 59 || se > 59) return 0;   /* 24:00 and :60 refused */

  days = psaml_days_from_civil(y, (unsigned)mo, (unsigned)da);
  *out = days * 86400 + ho * 3600 + mi * 60 + se - offset;
  return 1;
}

/* Formats as YYYY-MM-DDThh:mm:ssZ. Writes at most 40 bytes including the
 * NUL and returns the length written. UTC always: an identity provider
 * that received a local time with an offset would be entitled to read it
 * correctly and we would still have said something we did not mean. */
PERL_STATIC_INLINE STRLEN psaml_time_format(char *buf, STRLEN cap, IV t) {
  IV       days = t / 86400;
  IV       secs = t % 86400;
  IV       y;
  unsigned mo, da;
  int      n;
  if (secs < 0) { secs += 86400; days -= 1; }
  psaml_civil_from_days(days, &y, &mo, &da);
  n = my_snprintf(buf, (int)cap, "%04" IVdf "-%02u-%02uT%02u:%02u:%02uZ",
                  y, mo, da,
                  (unsigned)(secs / 3600), (unsigned)((secs / 60) % 60),
                  (unsigned)(secs % 60));
  return n > 0 ? (STRLEN)n : 0;
}

#endif /* PSAML_TIME_H */
