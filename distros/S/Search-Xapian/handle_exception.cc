#include <xapian.h>

extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
}

/* handle_exception function
 *
 * called in catch blocks to croak or rethrow in perl land
 */

void handle_exception(void) {
    try {
        throw;
    } catch (const Xapian::RangeError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::RangeError", (void *) new Xapian::RangeError(error));
        croak(Nullch);
    } catch (const Xapian::SerialisationError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::SerialisationError", (void *) new Xapian::SerialisationError(error));
        croak(Nullch);
    } catch (const Xapian::QueryParserError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::QueryParserError", (void *) new Xapian::QueryParserError(error));
        croak(Nullch);
    } catch (const Xapian::NetworkTimeoutError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::NetworkTimeoutError", (void *) new Xapian::NetworkTimeoutError(error));
        croak(Nullch);
    } catch (const Xapian::NetworkError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::NetworkError", (void *) new Xapian::NetworkError(error));
        croak(Nullch);
    } catch (const Xapian::InternalError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::InternalError", (void *) new Xapian::InternalError(error));
        croak(Nullch);
    } catch (const Xapian::FeatureUnavailableError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::FeatureUnavailableError", (void *) new Xapian::FeatureUnavailableError(error));
        croak(Nullch);
    } catch (const Xapian::DocNotFoundError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::DocNotFoundError", (void *) new Xapian::DocNotFoundError(error));
        croak(Nullch);
    } catch (const Xapian::DatabaseVersionError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::DatabaseVersionError", (void *) new Xapian::DatabaseVersionError(error));
        croak(Nullch);
    } catch (const Xapian::DatabaseOpeningError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::DatabaseOpeningError", (void *) new Xapian::DatabaseOpeningError(error));
        croak(Nullch);
    } catch (const Xapian::DatabaseModifiedError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::DatabaseModifiedError", (void *) new Xapian::DatabaseModifiedError(error));
        croak(Nullch);
    } catch (const Xapian::DatabaseLockError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::DatabaseLockError", (void *) new Xapian::DatabaseLockError(error));
        croak(Nullch);
    } catch (const Xapian::DatabaseCreateError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::DatabaseCreateError", (void *) new Xapian::DatabaseCreateError(error));
        croak(Nullch);
    } catch (const Xapian::DatabaseCorruptError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::DatabaseCorruptError", (void *) new Xapian::DatabaseCorruptError(error));
        croak(Nullch);
    } catch (const Xapian::DatabaseError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::DatabaseError", (void *) new Xapian::DatabaseError(error));
        croak(Nullch);
    } catch (const Xapian::UnimplementedError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::UnimplementedError", (void *) new Xapian::UnimplementedError(error));
        croak(Nullch);
    } catch (const Xapian::InvalidOperationError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::InvalidOperationError", (void *) new Xapian::InvalidOperationError(error));
        croak(Nullch);
    } catch (const Xapian::InvalidArgumentError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::InvalidArgumentError", (void *) new Xapian::InvalidArgumentError(error));
        croak(Nullch);
    } catch (const Xapian::AssertionError & error) {
	SV * errsv = get_sv("@", TRUE);
	sv_setref_pv(errsv, "Search::Xapian::AssertionError", (void *) new Xapian::AssertionError(error));
        croak(Nullch);
    } catch (const std::exception & error) {
        croak( "std::exception: %s", error.what());
    } catch (...) {
        croak("something terrible happened");
    }
}
