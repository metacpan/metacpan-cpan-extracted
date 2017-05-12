#include <kcharsets.h>

class KCharsetConverter {
    enum Flags {
        INPUT_AMP_SEQUENCES,
        OUTPUT_AMP_SEQUENCES,
        AMP_SEQUENCES,
        UNKNOWN_TO_ASCII,
        UNKNOWN_TO_QUESTION_MARKS
    };

    KCharsetConverter(KCharset, int = KCharsetConverter::UNKNOWN_TO_QUESTION_MARKS);
    KCharsetConverter(KCharset, KCharset, int = KCharsetConverter::UNKNOWN_TO_QUESTION_MARKS);
    ~KCharsetConverter();
    const KCharsetConversionResult &convert(const char *);
    const KCharsetConversionResult &convert(unsigned);
    const KCharsetConversionResult &convertTag(const char *);
    const KCharsetConversionResult &convertTag(const char *, int &);
;    const QList<KCharsetConversionResult> &multipleConvert(const char *);
    bool ok();
    const char *outputCharset();
} KDE::CharsetConverter;
