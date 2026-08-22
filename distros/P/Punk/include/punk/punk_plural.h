#ifndef PUNK_PLURAL_H
#define PUNK_PLURAL_H

/* CLDR plural categories.
 *
 * ---- why this is not `$count == 1` ----------------------------------------
 *
 * English has two forms. Polish has three. Arabic has six. Japanese has one.
 * A system that branches on `$count == 1` is English's grammar wearing a
 * plural system's name: it is wrong for Polish at 2, 3 and 4 and again at 22,
 * 23 and 24; it is wrong for Arabic at 0 and 2; and it is wrong SILENTLY,
 * because the sentence it produces is grammatical, just not for that number.
 *
 * So the rules are encoded as rules. Each language names a function from a
 * number to one of six categories, and a catalogue supplies a string per
 * category it uses:
 *
 *     "items": { "one": "{count} item", "other": "{count} items" }
 *
 * ---- the operands ----------------------------------------------------------
 *
 * CLDR rules are written over operands - n, i, v, w, f, t - where `n` is the
 * absolute value, `i` its integer part, and `v` the number of visible
 * fraction digits. This implements the integer case: `v` is 0 for a whole
 * number and non-zero otherwise, which is what every rule below needs.
 *
 * That distinction is not pedantry. In English `1` is `one` and `1.0` is
 * `other` - "1.0 items" - and the rules say so through `v = 0`. A count that
 * is not a whole number therefore takes the fractional branch, which in most
 * languages is `other`, and that is the correct answer rather than a
 * shortcut.
 *
 * ---- an unknown language is an ERROR, not English -------------------------
 *
 * There is no default rule. A catalogue that uses plural categories in a
 * language whose rule is not here fails AT BOOT, naming the locale. The
 * alternative - falling back to one/other - is precisely the bug this header
 * exists to prevent, and it would be invisible: Polish pages would read
 * plausibly and be wrong for a quarter of their numbers.
 */

typedef enum {
    PI_CAT_ZERO = 0, PI_CAT_ONE, PI_CAT_TWO,
    PI_CAT_FEW, PI_CAT_MANY, PI_CAT_OTHER,
    PI_CAT_N
} pi_pcat;

static const char *const PI_CAT_NAME[PI_CAT_N] = {
    "zero", "one", "two", "few", "many", "other"
};

/* The rule families. Languages share a rule far more often than not, which is
 * why this is a table of families rather than one entry per language. */
typedef enum {
    PR_NONE = -1,   /* no rule known - a boot error if plurals are used */
    PR_OTHER,       /* one form: ja, zh, ko, th, vi, id, ms, my         */
    PR_ONE,         /* one/other, `one` at exactly 1: en, de, nl, sv... */
    PR_ZERO_ONE,    /* one/other, `one` at 0 and 1: fr, hi              */
    PR_RUSSIAN,     /* one/few/many/other: ru, uk, be                   */
    PR_POLISH,      /* one/few/many/other, different from Russian: pl   */
    PR_CZECH,       /* one/few/many/other: cs, sk                       */
    PR_ARABIC,      /* all six: ar                                      */
    PR_ROMANIAN,    /* one/few/other: ro, mo                            */
    PR_LITHUANIAN,  /* one/few/many/other: lt                           */
    PR_N
} pi_rule;

/* Language subtag to rule. Matched on the PRIMARY subtag, so en-GB, en-US and
 * en all share English's rule - a region does not change a grammar. */
static const struct { const char *lang; pi_rule rule; } PI_RULES[] = {
    /* one form */
    { "ja", PR_OTHER }, { "zh", PR_OTHER }, { "ko", PR_OTHER },
    { "th", PR_OTHER }, { "vi", PR_OTHER }, { "id", PR_OTHER },
    { "ms", PR_OTHER }, { "my", PR_OTHER }, { "lo", PR_OTHER },
    { "km", PR_OTHER }, { "yo", PR_OTHER },

    /* one at exactly 1 */
    { "en", PR_ONE }, { "de", PR_ONE }, { "nl", PR_ONE }, { "sv", PR_ONE },
    { "da", PR_ONE }, { "no", PR_ONE }, { "nb", PR_ONE }, { "nn", PR_ONE },
    { "fi", PR_ONE }, { "et", PR_ONE }, { "el", PR_ONE }, { "it", PR_ONE },
    { "es", PR_ONE }, { "hu", PR_ONE }, { "tr", PR_ONE }, { "bg", PR_ONE },
    { "ca", PR_ONE }, { "eu", PR_ONE }, { "he", PR_ONE }, { "af", PR_ONE },
    { "sw", PR_ONE }, { "sq", PR_ONE }, { "ka", PR_ONE }, { "az", PR_ONE },
    { "gl", PR_ONE }, { "is", PR_ONE }, { "ur", PR_ONE }, { "ta", PR_ONE },
    { "te", PR_ONE }, { "ml", PR_ONE }, { "mr", PR_ONE }, { "ne", PR_ONE },

    /* one at 0 and 1 */
    { "fr", PR_ZERO_ONE }, { "hi", PR_ZERO_ONE }, { "pt", PR_ZERO_ONE },
    { "bn", PR_ZERO_ONE }, { "fa", PR_ZERO_ONE },

    /* the Slavic families, which differ from each other */
    { "ru", PR_RUSSIAN }, { "uk", PR_RUSSIAN }, { "be", PR_RUSSIAN },
    { "hr", PR_RUSSIAN }, { "sr", PR_RUSSIAN }, { "bs", PR_RUSSIAN },
    { "pl", PR_POLISH },
    { "cs", PR_CZECH },   { "sk", PR_CZECH },
    { "lt", PR_LITHUANIAN },
    { "ro", PR_ROMANIAN },

    { "ar", PR_ARABIC }
};

/* The rule for a language tag, or PR_NONE. */
static pi_rule pi_rule_for(const char *tag, STRLEN tl) {
    STRLEN prim = 0;
    size_t i;
    while (prim < tl && tag[prim] != '-') prim++;
    for (i = 0; i < sizeof PI_RULES / sizeof PI_RULES[0]; i++) {
        const char *l = PI_RULES[i].lang;
        if (strlen(l) == prim && memcmp(l, tag, prim) == 0)
            return PI_RULES[i].rule;
    }
    return PR_NONE;
}

/* Which category does `count` take under `rule`?
 *
 * `is_int` is the `v = 0` operand: false means the count has visible fraction
 * digits, which nearly every rule below routes to `other`.
 */
static pi_pcat pi_plural(pi_rule rule, double count, int is_int) {
    /* Rules are written over the ABSOLUTE value: -1 item and 1 item take the
     * same form in every language here. */
    double n = count < 0 ? -count : count;
    UV i = (UV)n;                    /* the integer part */
    UV i10, i100;

    if (!is_int) {
        /* The fractional branch. Only Czech and Romanian name it; everywhere
         * else a number with a fraction is `other`. */
        switch (rule) {
            case PR_CZECH:    return PI_CAT_MANY;
            case PR_ROMANIAN: return PI_CAT_FEW;
            default:          return PI_CAT_OTHER;
        }
    }

    i10  = i % 10;
    i100 = i % 100;

    switch (rule) {
        case PR_OTHER:
            return PI_CAT_OTHER;

        case PR_ONE:
            return (i == 1) ? PI_CAT_ONE : PI_CAT_OTHER;

        case PR_ZERO_ONE:
            return (i == 0 || i == 1) ? PI_CAT_ONE : PI_CAT_OTHER;

        case PR_RUSSIAN:
            if (i10 == 1 && i100 != 11) return PI_CAT_ONE;
            if (i10 >= 2 && i10 <= 4 && !(i100 >= 12 && i100 <= 14))
                return PI_CAT_FEW;
            return PI_CAT_MANY;

        case PR_POLISH:
            if (i == 1) return PI_CAT_ONE;
            if (i10 >= 2 && i10 <= 4 && !(i100 >= 12 && i100 <= 14))
                return PI_CAT_FEW;
            return PI_CAT_MANY;

        case PR_CZECH:
            if (i == 1) return PI_CAT_ONE;
            if (i >= 2 && i <= 4) return PI_CAT_FEW;
            return PI_CAT_OTHER;

        case PR_LITHUANIAN:
            if (i10 == 1 && !(i100 >= 11 && i100 <= 19)) return PI_CAT_ONE;
            if (i10 >= 2 && i10 <= 9 && !(i100 >= 11 && i100 <= 19))
                return PI_CAT_FEW;
            return PI_CAT_OTHER;

        case PR_ROMANIAN:
            if (i == 1) return PI_CAT_ONE;
            if (i == 0 || (i100 >= 1 && i100 <= 19)) return PI_CAT_FEW;
            return PI_CAT_OTHER;

        case PR_ARABIC:
            if (i == 0) return PI_CAT_ZERO;
            if (i == 1) return PI_CAT_ONE;
            if (i == 2) return PI_CAT_TWO;
            if (i100 >= 3 && i100 <= 10) return PI_CAT_FEW;
            if (i100 >= 11 && i100 <= 99) return PI_CAT_MANY;
            return PI_CAT_OTHER;

        default:
            return PI_CAT_OTHER;
    }
}

/* Is this key one of the six category names? Used at boot to tell a plural
 * map from an ordinary nested object. */
static int pi_cat_name(const char *k, STRLEN kl) {
    int i;
    for (i = 0; i < PI_CAT_N; i++) {
        const char *n = PI_CAT_NAME[i];
        if (strlen(n) == kl && memcmp(n, k, kl) == 0) return 1;
    }
    return 0;
}

#endif /* PUNK_PLURAL_H */
