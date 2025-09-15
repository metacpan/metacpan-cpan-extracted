import { Head, Link } from '@inertiajs/react'

export default function Index() {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4">
      <Head title="Home" />
      <div className="max-w-2xl mx-auto">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">
          Mojolicious + React + Inertia.js
        </h1>

        <nav className="space-y-2">
          <Link
            href="/hello"
            className="block p-4 bg-white rounded-lg border border-gray-200 hover:border-blue-500 transition-colors"
          >
            Hello Page
          </Link>

          <Link
            href="/todos"
            className="block p-4 bg-white rounded-lg border border-gray-200 hover:border-blue-500 transition-colors"
          >
            Todo List
          </Link>

          <Link
            href="/dashboard"
            className="block p-4 bg-white rounded-lg border border-gray-200 hover:border-blue-500 transition-colors"
          >
            Dashboard
          </Link>
        </nav>
      </div>
    </div>
  )
}
