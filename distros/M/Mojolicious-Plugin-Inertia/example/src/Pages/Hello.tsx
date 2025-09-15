import { Head, Link } from '@inertiajs/react'

interface Props {
  user: {
    name: string
  }
}

export default function Hello({ user }: Props) {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4">
      <Head title="Hello" />
      <div className="max-w-2xl mx-auto">
        <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-4">
            Hello, {user.name}!
          </h1>
          <p className="text-gray-600 mb-6">
            Welcome to the Mojolicious + Inertia.js example application.
          </p>
          <Link
            href="/"
            className="inline-block px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Back to Home
          </Link>
        </div>
      </div>
    </div>
  )
}