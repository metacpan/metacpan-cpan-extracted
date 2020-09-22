# Serving MARC records from FOLIO's Source Record Storage

<!-- md2toc -l 2 using-srs.md -->
* [Introduction](#introduction)
* [Finding example SRS records](#finding-example-srs-records)
* [Understanding the data import APIs](#understanding-the-data-import-apis)
* [Uploading example SRS records from the UI](#uploading-example-srs-records-from-the-ui)
* [What next?](#what-next)


## Introduction

FOLIO stores inventory information using its own
[`mod-inventory`](https://github.com/folio-org/mod-inventory)
module, which is a thinnish business-logic layer over the lower level
[`mod-inventory-storage`](https://github.com/folio-org/mod-inventory-storage)
module. `mod-inventory-storage` defines the FOLIO inventory formats: one each for
[instance records](https://github.com/folio-org/mod-inventory-storage/blob/master/ramls/instance.json),
[holdings records](https://github.com/folio-org/mod-inventory-storage/blob/master/ramls/holdingsrecord.json)
and
[item records](https://github.com/folio-org/mod-inventory-storage/blob/master/ramls/item.json).

However, many libraries remain wedded to [MARC records](https://en.wikipedia.org/wiki/MARC_standards), a standard from the 1960s that has comfortably outlives many of the citics who have pronounced its death over the years. FOLIO therefore provides a Source Record Storage (SRS) facility. Using this, MARC records may be uploaded to a FOLIO service. When this upload is performed using
[`mod-data-import`](https://github.com/folio-org/mod-data-import),
the records are automatically converted into instance records which are inked to the source records -- the latter being retained by the system and remaining the version of record.

The MARC format also remains important as the principal form in which [Z39.50](https://en.wikipedia.org/wiki/Z39.50) servers provide records to clients. [The FOLIO Z39.50 server](https://github.com/folio-org/Net-Z3950-FOLIO) can return XML records that are a transliteration of the JSON format for instances, but it is also required to serve MARC records -- for example, so it can provide relevant information to ILL systems.

[Issue ZF-05](https://issues.folio.org/browse/ZF-5) is to extend the Z93.50 server so that, when MARC records are requested, the server fetches the relevant records from SRS and returns them. To do this, it's necessary to locate a back-end service with sample SRS records, or create some; and to have the Z39.50 server issue requests to the SRS WSAPI. Both these steps are non-trivial.


## Finding example SRS records

It turns out that there are no SRS reference records, analogous to the reference records that are provided by `mod-inventory-storage` and which therefore turn up on each new build of reference environments such as [folio-snapshot](https://folio-snapshot.dev.folio.org/). That is unfortunate: such records would have been easy to work with, and to write test suites around.

There are specific servers, mostly beonging to customers, that do contain SRS records, but we cannot depend on these to remain in any given state such that tests can be reliably run against them. Similarly, bugfest environments like [bugfest-goldenrod](https://bugfest-goldenrod.folio.ebsco.com/) may contain SRS records, but their content cannot be relied upon to stay constant for tests.

As a result, it seems we have little option but to obtain a set of MARC records and insert them into a reference environment ourselves. (Or perhaps once such records exist, they could fairly easily be added as reference data to
[`mod-source-record-storage`](https://github.com/folio-org/mod-source-record-storage)
-- but that is for another day.)

For now, we need to understand the APIs that will let us add records.


## Understanding the data import APIs

The WSAPI of `mod-source-record-storage` has [documentation generated automatically](https://dev.folio.org/reference/api/#mod-source-record-storage) from its RAML and JSON files, like all RMB-based modules. However, there is no high-level overview documentation, and in its absence it is difficult to understand how the pieces fit together. The module provides six separate RAML files and there is no obvious guidance on when, for example, one would prefer the APIs provided by `source-record-storage-records` over those provided by `source-record-storage-source-records`.

To make matters more confusing, there is also a [`mod-source-record-manager`](https://github.com/folio-org/mod-source-record-manager/)
module which _presumably_ implements a higher-level "business logic" interface over `mod-source-record-storage`. It provides [four RAML files of its own](https://dev.folio.org/reference/api/#mod-source-record-manager) and a complex API that involves JobExecutions, jobProfileInfos, sourceTypes, RawRecordsDTos and other such exotica. Thankfully there is [some documentation for this](https://github.com/folio-org/mod-source-record-manager/#data-import-workflow), but it assumes quite a bit of pre-existing knowledge.

Above this is yet another layer,
[`mod-data-import`](https://github.com/folio-org/mod-data-import/),
which may or may not also use
[`mod-data-import-converter-storage`](https://github.com/folio-org/mod-data-import-converter-storage/)
and/or
[`mod-data-loader`](https://github.com/folio-org/mod-data-loader/).
Documentation of these modules is variable in quality, and I have not been able to find any high-level documentation explaining how they all fit together (though that does not mean that no such document exists).


## Uploading example SRS records from the UI

So instead of trying to make sense of the APIs, perhaps the most pragmatic approach is just to exercise the data-import facility provided by the FOLIO UI, and use the browser's network-tracing tools to see what requests are sent.

Tracking the network requests is made trickier because [the Data Import app](https://folio-snapshot.dev.folio.org/data-import/) re-fetches its list every five seconds, making two additional requests. But as far as I can make out, the sequence is as follows:

1. GET `/data-import/uploadDefinitions` with two parameters: `limit` set to 1, and `query` to `(status==("NEW" OR "IN_PROGRESS" OR "LOADED")) sortBy createdDate/sort.descending` -- returning no records.

2. POST to `/data-import/uploadDefinitions` with data:
```
	{
	  "fileDefinitions": [
	    {
	      "uiKey": "100 Sample MARC Records.mrc1597335464878",
	      "size": 145,
	      "name": "100 Sample MARC Records.mrc"
	    }
	  ]
	}
```

3. The same query as #1, but this time returning one record, corresponding to the one we just POSTed.
```
	{
	  "uploadDefinitions": [
	    {
	      "id": "83447cac-8dfc-45fa-8c70-a34f7082c57d",
	      "metaJobExecutionId": "572bbcda-008a-4719-87ca-6433fbb218aa",
	      "status": "NEW",
	      "createDate": "2020-08-17T10:46:35.105+0000",
	      "fileDefinitions": [
	        {
	          "id": "a909e806-2804-45d1-88e6-1d30719d211d",
	          "name": "100 Sample MARC Records.mrc",
	          "status": "NEW",
	          "jobExecutionId": "572bbcda-008a-4719-87ca-6433fbb218aa",
	          "uploadDefinitionId": "83447cac-8dfc-45fa-8c70-a34f7082c57d",
	          "createDate": "2020-08-17T10:46:35.105+0000",
	          "size": 145,
	          "uiKey": "100 Sample MARC Records.mrc1597335464878"
	        }
	      ],
	      "metadata": {
	        "createdDate": "2020-08-17T10:46:35.102+0000",
	        "createdByUserId": "d50e80fd-6d59-5485-adf2-809672645cb0",
	        "updatedDate": "2020-08-17T10:46:35.102+0000",
	        "updatedByUserId": "d50e80fd-6d59-5485-adf2-809672645cb0"
	      }
	    }
	  ],
	  "totalRecords": 1
	}
```

4. POST to `/data-import/uploadDefinitions/83447cac-8dfc-45fa-8c70-a34f7082c57d/files/a909e806-2804-45d1-88e6-1d30719d211d` -- but, infuriatingly, The "Copy POST data" option in Firefox's developer tools doesn't copy anything. I would _guess_ that this is where the actual MARC data is POSTed.

5. GET `/data-import/fileExtensions?query=extension==".mrc"`, yielding this structure:
```
	{
	  "fileExtensions": [
	    {
	      "id": "f445092c-94b8-408a-a9f1-5edd8b5919c9",
	      "description": "",
	      "extension": ".mrc",
	      "dataTypes": [
	        "MARC"
	      ],
	      "importBlocked": false,
	      "userInfo": {
	        "firstName": "",
	        "lastName": "",
	        "userName": "System"
	      },
	      "metadata": {
	        "createdDate": "2019-01-01T11:22:07.000+0000",
	        "createdByUserId": "00000000-0000-0000-0000-000000000000",
	        "createdByUsername": "System",
	        "updatedDate": "2019-01-01T11:22:07.000+0000",
	        "updatedByUserId": "00000000-0000-0000-0000-000000000000",
	        "updatedByUsername": "System"
	      }
	    }
	  ],
	  "totalRecords": 1
	}
```
I have no idea why the front-end would care about any of this.

6. GET `/data-import-profiles/jobProfiles` with `limit` 5000, yielding an empty list.

7. GET `/data-import-profiles/jobProfiles` with `limit` 5000 and query `(dataType==("MARC")) sortby name`, also yielding an empty list.

At this point, network request cease until you choose **Load MARC bibliographic records** from the **Actions** button to top left. Then the following further operations happen:

8. GET `https://folio-snapshot-okapi.dev.folio.org/data-import/uploadDefinitions/83447cac-8dfc-45fa-8c70-a34f7082c57d`
```
	{
	  "id": "83447cac-8dfc-45fa-8c70-a34f7082c57d",
	  "metaJobExecutionId": "572bbcda-008a-4719-87ca-6433fbb218aa",
	  "status": "LOADED",
	  "createDate": "2020-08-17T10:46:35.105+0000",
	  "fileDefinitions": [
	    {
	      "id": "a909e806-2804-45d1-88e6-1d30719d211d",
	      "sourcePath": "./storage/upload/83447cac-8dfc-45fa-8c70-a34f7082c57d/a909e806-2804-45d1-88e6-1d30719d211d/100 Sample MARC Records.mrc",
	      "name": "100 Sample MARC Records.mrc",
	      "status": "UPLOADED",
	      "jobExecutionId": "572bbcda-008a-4719-87ca-6433fbb218aa",
	      "uploadDefinitionId": "83447cac-8dfc-45fa-8c70-a34f7082c57d",
	      "createDate": "2020-08-17T10:46:35.105+0000",
	      "uploadedDate": "2020-08-17T10:46:35.855+0000",
	      "size": 145,
	      "uiKey": "100 Sample MARC Records.mrc1597335464878"
	    }
	  ],
	  "metadata": {
	    "createdDate": "2020-08-17T10:46:35.102+0000",
	    "createdByUserId": "d50e80fd-6d59-5485-adf2-809672645cb0",
	    "updatedDate": "2020-08-17T10:46:35.102+0000",
	    "updatedByUserId": "d50e80fd-6d59-5485-adf2-809672645cb0"
	  }
	}
```
(This is very similar to a subrecord of the earlier response #3.)

9. POST to `/data-import/uploadDefinitions/83447cac-8dfc-45fa-8c70-a34f7082c57d/processFiles` with `defaultMapping` set true. The POSTed data is:
```
	{
	  "uploadDefinition": {
	    "id": "83447cac-8dfc-45fa-8c70-a34f7082c57d",
	    "metaJobExecutionId": "572bbcda-008a-4719-87ca-6433fbb218aa",
	    "status": "LOADED",
	    "createDate": "2020-08-17T10:46:35.105+0000",
	    "fileDefinitions": [
	      {
	        "id": "a909e806-2804-45d1-88e6-1d30719d211d",
	        "sourcePath": "./storage/upload/83447cac-8dfc-45fa-8c70-a34f7082c57d/a909e806-2804-45d1-88e6-1d30719d211d/100 Sample MARC Records.mrc",
	        "name": "100 Sample MARC Records.mrc",
	        "status": "UPLOADED",
	        "jobExecutionId": "572bbcda-008a-4719-87ca-6433fbb218aa",
	        "uploadDefinitionId": "83447cac-8dfc-45fa-8c70-a34f7082c57d",
	        "createDate": "2020-08-17T10:46:35.105+0000",
	        "uploadedDate": "2020-08-17T10:46:35.855+0000",
	        "size": 145,
	        "uiKey": "100 Sample MARC Records.mrc1597335464878"
	      }
	    ],
	    "metadata": {
	      "createdDate": "2020-08-17T10:46:35.102+0000",
	      "createdByUserId": "d50e80fd-6d59-5485-adf2-809672645cb0",
	      "updatedDate": "2020-08-17T10:46:35.102+0000",
	      "updatedByUserId": "d50e80fd-6d59-5485-adf2-809672645cb0"
	    }
	  },
	  "jobProfileInfo": {
	    "id": "22fafcc3-f582-493d-88b0-3c538480cd83",
	    "name": "Create MARC Bibs",
	    "dataType": "MARC"
	  }
	}
```
This makes no sense to me. Why would a new POST repeat something we'd been given from the back-end?

10. Another repeat of #1 and #3, this time once more returning an empty list.

Wow. This is one of the most bizarrely over-engineered APIs I have ever seen. _Clearly_ what is actually needed is a single endpoint, `/data-import/marcbatch`, where you POST of file of MARC records, end of.


## What next?

At this stage, I was seriously considering whether it would be easier to add sample batches of record to a test server by automating the UI with [Cypress](https://www.cypress.io/) than by trying to drive this complex and largely undocumented API.

On more mature consideration, it must be the case that many of the steps in this ten-step process do not pertain to the upload, but just to updating the UI -- so will not be needed in a batch-upload process.

Having now chatted with Kateryna Senchenko it's apparent that this is correct: only the three POST steps are necessary to upload and process a file of MARC records. I will create a script that does this.

