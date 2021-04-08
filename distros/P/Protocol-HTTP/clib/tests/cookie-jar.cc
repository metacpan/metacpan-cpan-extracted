#include "test.h"

#define TEST(name) TEST_CASE("cookie-jar: " name, "[cookie_jar]")

auto now     = panda::date::Date::now();
auto past    = now - 3600;
auto ancient = now - 3600 * 5;
auto future  = now + 3600;

TEST("add cookie") {
    CookieJarSP jar(new CookieJar());
    auto& dc = jar->domain_cookies;
    URISP origin(new URI("https://www.perl.org/my-path"));

    Response::Cookie coo("v");
    coo.domain("crazypanda.ru");
    coo.path("/p");

    SECTION("no domain -> get it from origin") {
        coo.domain("");
        coo.path("/p");
        jar->add("k", coo, origin);
        CHECK(dc.size() == 1);
        CHECK(dc[".www.perl.org"][0].host_only() == true);
    }

    SECTION("session cookie is added") {
        jar->add("k", coo, origin);
        CHECK(dc.size() == 1);
        CHECK(dc.count(".crazypanda.ru") == 1);
        CHECK(dc[".crazypanda.ru"][0].name() == "k");
        Response::Cookie &coo = dc[".crazypanda.ru"][0]; /* downcast */
        CHECK(coo.to_string("k") == coo.to_string("k"));
    }

    SECTION("non-expired cookie is added") {
        coo.expires(future);
        jar->add("k", coo, origin, now);
        CHECK(dc.size() == 1);
    }

    SECTION("expired cookie isn't added") {
        coo.expires(past);
        jar->add("k", coo, origin, now);
        CHECK(dc.size() == 0);
    }

    SECTION("2 cookies on same domain with differen paths are added") {
        jar->add("k", coo, origin);
        coo.path("/p2");
        jar->add("k", coo, origin);
        CHECK(dc.size() == 1);
        auto& cookies = dc[".crazypanda.ru"];
        CHECK(cookies.size() == 2);
    }

    SECTION("2 cookies on different domains are addred") {
        jar->add("k", coo, origin);
        coo.domain("example.org");
        jar->add("k", coo, origin);
        CHECK(dc.size() == 2);
    }

    SECTION("updated") {
        jar->add("k", coo, origin);
        coo.value("v2");
        jar->add("k", coo, origin);
        auto& cookies = dc[".crazypanda.ru"];
        CHECK(cookies.size() == 1);
        CHECK(cookies[0].value() == "v2");
    }

    SECTION("remove cookie") {
        jar->add("k", coo, origin);
        coo.expires(past);
        jar->add("k", coo, origin, now);
        CHECK(dc.size() == 0);
    }

    SECTION("remove cookie") {
        coo.path("");
        jar->add("k", coo, origin);
        jar->add("k", coo, origin, past);
        REQUIRE(dc.size() == 1);
        auto& cookies = dc[".crazypanda.ru"];
        CHECK(cookies.at(0).path() == "/my-path");
    }
}

TEST("remove cookies") {
    CookieJarSP jar(new CookieJar());
    auto& dc = jar->domain_cookies;
    URISP origin(new URI("https://www.perl.org/my-path"));

    Response::Cookie coo("v");
    coo.domain("crazypanda.ru");
    coo.path("/p");
    jar->add("c1", coo, origin);

    Response::Cookie coo2("v");
    coo.domain("crazypanda.ru");
    coo.path("/");
    jar->add("c2", coo, origin);

    Response::Cookie coo3("v");
    coo.domain("poker.crazypanda.ru");
    coo.path("/perl");
    jar->add("c3", coo, origin);

    Response::Cookie coo4("v");
    coo.domain("poker.crazypanda.ru");
    coo.path("/cpp");
    jar->add("c4", coo, origin);

    REQUIRE(!dc.empty());

    SECTION("by domain") {
        SECTION("all") {
            auto cookies = jar->remove("crazypanda.ru");
            CHECK(dc.empty());
            CHECK(cookies.size() == 4);
        }

        SECTION("patrial") {
            auto cookies = jar->remove("poker.crazypanda.ru");
            CHECK(!dc.empty());
            CHECK(cookies.size() == 2);
            CHECK(cookies[0].name() == "c3");
            CHECK(cookies[1].name() == "c4");
        }

        SECTION("none") {
            auto cookies = jar->remove("panda.ru");
            CHECK(!dc.empty());
            CHECK(cookies.size() == 0);
        }

        SECTION("strict") {
            auto cookies = jar->remove(".crazypanda.ru");
            CHECK(!dc.empty());
            CHECK(cookies.size() == 2);
            CHECK(cookies[0].name() == "c1");
            CHECK(cookies[1].name() == "c2");
        }
    }

    SECTION("by name") {
        auto cookies = jar->remove("", "c4");
        CHECK(!dc.empty());
        CHECK(cookies.size() == 1);
        CHECK(cookies[0].name() == "c4");
    }

    SECTION("by path") {
        SECTION("prefix") {
            auto cookies = jar->remove("", "", "/p");
            CHECK(!dc.empty());
            CHECK(cookies.size() == 2);
            CHECK(cookies[0].name() == "c3");
            CHECK(cookies[1].name() == "c1");
        }

        SECTION("full path") {
            auto cookies = jar->remove("", "", "/perl");
            CHECK(!dc.empty());
            CHECK(cookies.size() == 1);
            CHECK(cookies[0].name() == "c3");
        }
    }

    SECTION("all") {
        auto cookies = jar->remove();
        CHECK(dc.empty());
        CHECK(cookies.size() == 4);
    }

    SECTION("full match") {
        auto cookies = jar->remove(".poker.crazypanda.ru", "c3", "/perl");
        CHECK(!dc.empty());
        CHECK(cookies.size() == 1);
        CHECK(cookies[0].name() == "c3");
    }
}

TEST("find/match cookie") {
    CookieJarSP jar(new CookieJar());

    URISP origin(new URI("https://perl.perl.org/"));

    Response::Cookie coo1("v1");
    coo1.domain("crazypanda.ru");
    coo1.path("/p1");
    coo1.expires(now);

    Response::Cookie coo2("v2");
    coo2.domain("crazypanda.ru");
    coo2.path("/p1/p2");
    coo2.expires(now);

    Response::Cookie coo3("v3");
    coo3.domain("perl.crazypanda.ru");
    coo3.path("/pp3");
    coo3.expires(past);
    coo3.secure(true);

    jar->add("k1", coo1, origin, ancient);
    jar->add("k2", coo2, origin, ancient);
    jar->add("k3", coo3, origin, ancient);

    SECTION("prepreq"){
        auto& dc = jar->domain_cookies;
        auto cookies = &dc.at(".crazypanda.ru");
        REQUIRE(cookies->size() == 2);
        REQUIRE(cookies->at(0).name() == "k1");
        REQUIRE(cookies->at(1).name() == "k2");

        cookies = &dc.at(".perl.crazypanda.ru");
        REQUIRE(cookies->size() == 1);
        REQUIRE(cookies->at(0).name() == "k3");
    }

    SECTION("find nothing (path mismatch)") {
        auto cookies = jar->find(URISP{new URI("http://crazypanda.ru/404")}, past);
        REQUIRE(cookies.size() == 0);
    }

    SECTION("find nothing (domain mismatch)") {
        auto cookies = jar->find(URISP{new URI("http://example.org/")});
        REQUIRE(cookies.size() == 0);
    }

    SECTION("find most precise") {
        auto cookies = jar->find(URISP{new URI("http://crazypanda.ru/p1/p2")}, past);
        REQUIRE(cookies.size() == 1);
        auto& c = cookies[0];
        CHECK(c.name() == "k2");
        CHECK(c.value() == "v2");
    }

    SECTION("2 of 3 match (by path)") {
        auto cookies = jar->find(URISP{new URI("http://crazypanda.ru/p1")}, past);
        REQUIRE(cookies.size() == 2);
        CHECK(cookies[0].name() == "k2");
        CHECK(cookies[1].name() == "k1");
    }

    SECTION("2 of 3 match (by domain)") {
        auto cookies = jar->find(URISP{new URI("https://crazypanda.ru/p")}, past);
        REQUIRE(cookies.size() == 2);
        CHECK(cookies[0].name() == "k2");
        CHECK(cookies[1].name() == "k1");
    }

    SECTION("3 of 3 match (by domain)") {
        auto cookies = jar->find(URISP{new URI("https://perl.crazypanda.ru/")}, past);
        REQUIRE(cookies.size() == 3);
        CHECK(cookies[0].name() == "k2");
        CHECK(cookies[1].name() == "k3");
        CHECK(cookies[2].name() == "k1");
    }

    SECTION("2 of 3 match (by domain, and security)") {
        auto cookies = jar->find(URISP{new URI("http://perl.crazypanda.ru/")}, past);
        REQUIRE(cookies.size() == 2);
        CHECK(cookies[0].name() == "k2");
        CHECK(cookies[1].name() == "k1");
    }

    SECTION("3 of 3 match (by subdomain)") {
        auto cookies = jar->find(URISP{new URI("https://cpp.and.perl.crazypanda.ru/")}, past);
        REQUIRE(cookies.size() == 3);
        CHECK(cookies[0].name() == "k2");
        CHECK(cookies[1].name() == "k3");
        CHECK(cookies[2].name() == "k1");
    }

    SECTION("3 of 3 match by subdomain, but mismatch my date") {
        auto cookies = jar->find(URISP{new URI("https://cpp.and.perl.crazypanda.ru/")}, future);
        REQUIRE(cookies.size() == 0);
    }

    SECTION("3 of 3 match by subdomain, 2 match my date") {
        auto cookies = jar->find(URISP{new URI("https://perl.crazypanda.ru/")}, now);
        REQUIRE(cookies.size() == 2);
        CHECK(cookies[0].name() == "k2");
        CHECK(cookies[1].name() == "k1");
    }

    SECTION("same-site policy") {
        CookieJarSP jar(new CookieJar());
        REQUIRE(jar->domain_cookies.size() == 0);

        URISP origin(new URI("https://my.crazypanda.ru/"));

        Response::Cookie coo1("v1");
        coo1.domain("crazypanda.ru");
        coo1.path("/p1");
        coo1.expires(future);

        Response::Cookie coo4("v4");
        coo4.domain("crazypanda.ru");
        coo4.path("/cpp");
        coo4.expires(future);
        coo4.same_site(Response::Cookie::SameSite::Strict);

        Response::Cookie coo5("v5");
        coo5.domain("crazypanda.ru");
        coo5.path("/cpp");
        coo5.expires(future);
        coo5.same_site(Response::Cookie::SameSite::Lax);

        jar->add("k1", coo1, origin, ancient);
        jar->add("k4", coo4, origin, ancient);
        jar->add("k5", coo5, origin, ancient);

        auto& dc = jar->domain_cookies;
        REQUIRE(dc.at(".crazypanda.ru").size() == 3);

        SECTION("request matches origin") {
            auto cookies = jar->find(origin, now);
            REQUIRE(cookies.size() == 3);
        }

        SECTION("different site") {
            auto cookies = jar->find(URISP{new URI("https://public.crazypanda.ru/")}, past);
            REQUIRE(cookies.size() == 1);
            CHECK(cookies[0].name() == "k1");
        }

        SECTION("different site, lax context") {
            auto cookies = jar->find(URISP{new URI("https://public.crazypanda.ru/")}, past, true);
            REQUIRE(cookies.size() == 2);
            CHECK(cookies[0].name() == "k5");
            CHECK(cookies[1].name() == "k1");
        }

        SECTION("subdomain") {
            auto cookies = jar->find(URISP{new URI("https://static.my.crazypanda.ru/")}, past);
            REQUIRE(cookies.size() == 3);
        }
    }

    SECTION("session cookies") {
        CookieJarSP jar(new CookieJar());
        Response::Cookie coo1("v1");
        coo1.domain("crazypanda.ru");
        coo1.path("/p1");
        jar->add("k1", coo1, origin);
        auto cookies = jar->find(URISP{new URI("https://games.crazypanda.ru/")});
        REQUIRE(cookies.size() == 1);
    }

    SECTION("host-only cookies (missing domain)") {
        CookieJarSP jar(new CookieJar());
        auto origin = URISP{new URI("https://ya.ru/")};
        Response::Cookie coo1("v1");
        jar->add("k1", coo1, origin);
        auto cookies = jar->find(origin);
        REQUIRE(cookies.size() == 1);

        cookies = jar->find(URISP{new URI("https://www.ya.ru/")});
        REQUIRE(cookies.size() == 0);
    }
}

TEST("cookies collection from the request") {
    CookieJarSP jar(new CookieJar());

    URISP req_uri = new URI("http://games.crazypanda.ru/hello/world");
    auto res = Response::Builder()
            .cookie("c1", Response::Cookie("v1"))
            .cookie("c2", Response::Cookie("v2").domain("crazypanda.ru").path("/hi"))
            .cookie("c3", Response::Cookie("v3").domain("google.com"))
            .build();


    SECTION("same origin -> 2 cookies") {
        jar->collect(*res, req_uri);
        auto cookies = jar->find(URISP{new URI("http://games.crazypanda.ru")});
        REQUIRE(cookies.size() == 2);
        CHECK(cookies[0].name() == "c1");
        CHECK(cookies[1].name() == "c2");
    }

    SECTION("differnt subdomain -> 1 cookie") {
        jar->collect(*res, req_uri);
        auto cookies = jar->find(URISP{new URI("http://ww.games.crazypanda.ru")});
        REQUIRE(cookies.size() == 1);
        CHECK(cookies[0].name() == "c2");
    }

    SECTION("ignore predicate") {
        CookieJar::ignore_fn fn([](auto&, auto&){ return true; });
        jar->set_ignore(fn);
        jar->collect(*res, req_uri);
        auto cookies = jar->find(URISP{new URI("http://games.crazypanda.ru")});
        REQUIRE(cookies.size() == 0);
    }
}

TEST("cookies population to thr response") {
    CookieJarSP jar(new CookieJar());
    URISP uri(new URI("https://crazypanda.ru/"));
    Response::Cookie coo1("v1");
    jar->add("k1", coo1, uri);

    auto req = Request::Builder().uri(uri).build();
    REQUIRE(req->cookies.size() == 0);
    jar->populate(*req);
    REQUIRE(req->cookies.size() == 1);
    CHECK(req->cookies.get("k1") == "v1");
}

TEST("(de)serialization") {
    URISP origin(new URI("https://www.tut.by"));
    CookieJarSP jar(new CookieJar());

    SECTION("single cookie serialization") {
        auto& dc = jar->domain_cookies;
        Response::Cookie coo("v");
        coo.domain("tut.by");
        coo.path("/news");
        jar->add("k", coo, origin);

        REQUIRE(dc.size() == 1);
        REQUIRE(dc.count(".tut.by") == 1);
        CHECK(dc[".tut.by"][0].name() == "k");

        auto &jcoo = dc[".tut.by"][0];
        REQUIRE(jcoo.to_string() == "{\"key\":\"k\", \"value\":\"v\", \"domain\":\"tut.by\", \"path\":\"/news\"}");

        CHECK(jar->to_string(true) == "[\n{\"key\":\"k\", \"value\":\"v\", \"domain\":\"tut.by\", \"path\":\"/news\"}]");
        CHECK(jar->to_string(false) == "[\n]");

        CookieJar::DomainCookies dc2;
        REQUIRE(CookieJar::parse_cookies(jar->to_string(true), dc2) == std::error_code());
        REQUIRE(dc2[".tut.by"].size() == 1);
        CHECK(dc2[".tut.by"][0].to_string() == jcoo.to_string());
    }

    SECTION("by date filtration") {
        panda::time::tzset("Europe/Moscow");
        panda::date::Date expires(2020, 05, 18, 5);
        auto past = expires - 3600;
        auto future = expires + 3600;

        Response::Cookie coo("v");
        coo.domain("tut.by");
        coo.path("/news");
        coo.expires(expires);
        jar->add("k", coo, origin, past);

        CHECK(jar->to_string(false, past) == "[\n{\"key\":\"k\", \"value\":\"v\", \"domain\":\"tut.by\", \"path\":\"/news\", \"expires\":\"1589767200\"}]");
        CHECK(jar->to_string(false, future) == "[\n]");
    }

    SECTION("samesite & origin") {
        Response::Cookie coo("v");
        coo.domain("tut.by");
        coo.same_site(Response::Cookie::SameSite::Strict);
        jar->add("k", coo, origin);
        CHECK(jar->to_string(true) == "[\n{\"key\":\"k\", \"value\":\"v\", \"domain\":\"tut.by\", \"path\":\"/\", \"same_site\":\"S\", \"origin\":\"https://www.tut.by\"}]");
    }

    SECTION("samesite & origin") {
        Response::Cookie coo("v");
        jar->add("k", coo, origin);
        CHECK(jar->to_string(true) == "[\n{\"key\":\"k\", \"value\":\"v\", \"domain\":\"www.tut.by\", \"path\":\"/\", \"host_only\":\"1\"}]");
    }

    SECTION("parsing") {
        string data = R"DATA([
{"key":"k1", "value":"v1", "domain":"tut.by", "path":"/", "same_site":"S", "origin":"https://www.tut.by", "same_site":"S"},
{"key":"k2", "value":"v2", "domain":"ya.ru", "path":"/", "host_only":"1"}])DATA";
        CookieJarSP jar(new CookieJar(data));
        auto& dc = jar->domain_cookies;

        REQUIRE(dc[".tut.by"].size() == 1);
        auto& c1 = dc[".tut.by"][0];
        CHECK(c1.name() == "k1");
        CHECK(c1.value() == "v1");
        CHECK(c1.domain() == "tut.by");
        CHECK(c1.same_site() == Response::Cookie::SameSite::Strict);
        CHECK(c1.origin()->to_string() == "https://www.tut.by");

        REQUIRE(dc[".ya.ru"].size() == 1);
        auto& c2 = dc[".ya.ru"][0];
        CHECK(c2.name() == "k2");
        CHECK(c2.value() == "v2");
        CHECK(c2.domain() == "ya.ru");
        CHECK(c2.host_only());
    }
}
